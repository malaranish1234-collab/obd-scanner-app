import 'bluetooth_service.dart';
import '../models/dtc_database.dart';

class VehicleSnapshot {
  final int? rpm;
  final int? speedKmh;
  final int? coolantTempC;
  final double? batteryVoltage;
  final int? throttlePercent;
  final DateTime timestamp;

  VehicleSnapshot({
    this.rpm,
    this.speedKmh,
    this.coolantTempC,
    this.batteryVoltage,
    this.throttlePercent,
    required this.timestamp,
  });
}

/// Talks ELM327/OBD-II protocol over the Bluetooth SPP link and exposes
/// clean, typed results (live data + fault codes) to the UI layer.
class ObdService {
  final ObdBluetoothService _bt;
  ObdService(this._bt);

  /// Standard ELM327 init sequence — resets adapter, disables echo,
  /// disables line feed, sets protocol to auto-detect.
  Future<void> initializeAdapter() async {
    await _send('ATZ'); // reset
    await _send('ATE0'); // echo off
    await _send('ATL0'); // linefeeds off
    await _send('ATS0'); // spaces off
    await _send('ATSP0'); // auto-detect protocol
  }

  Future<String> _send(String cmd) async {
    final raw = await _bt.sendCommand(cmd);
    return _clean(raw);
  }

  String _clean(String raw) {
    return raw.replaceAll('>', '').replaceAll('\r', ' ').trim();
  }

  /// Reads a snapshot of common live PIDs (Mode 01).
  /// If a given sensor isn't supported by the vehicle, that field stays null
  /// rather than the whole read failing.
  Future<VehicleSnapshot> readLiveSnapshot() async {
    final rpmHex = await _safeSend('010C');
    final speedHex = await _safeSend('010D');
    final coolantHex = await _safeSend('0105');
    final voltageResp = await _safeSend('ATRV'); // adapter-reported voltage
    final throttleHex = await _safeSend('0111');

    return VehicleSnapshot(
      rpm: _parseRpm(rpmHex),
      speedKmh: _parseSingleByte(speedHex, offset: 0),
      coolantTempC: _parseSingleByte(coolantHex, offset: -40),
      batteryVoltage: _parseVoltage(voltageResp),
      throttlePercent: _parseThrottle(throttleHex),
      timestamp: DateTime.now(),
    );
  }

  Future<String?> _safeSend(String cmd) async {
    try {
      return await _send(cmd);
    } catch (_) {
      return null; // sensor not supported / no response — don't crash the scan
    }
  }

  /// Reads stored DTCs via Mode 03 and returns them enriched with
  /// plain-language descriptions from the local DTC database.
  Future<List<DtcInfo>> readFaultCodes() async {
    final resp = await _safeSend('03');
    if (resp == null) return [];
    return _parseDtcResponse(resp);
  }

  /// Clears stored DTCs (Mode 04). Use with a confirmation step in the UI —
  /// this also resets the MIL/check-engine indicator.
  Future<void> clearFaultCodes() async {
    await _send('04');
  }

  // ---- Parsing helpers ----

  List<int> _hexBytes(String resp) {
    final tokens = resp.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final bytes = <int>[];
    for (final t in tokens) {
      final v = int.tryParse(t, radix: 16);
      if (v != null) bytes.add(v);
    }
    return bytes;
  }

  int? _parseRpm(String? resp) {
    if (resp == null) return null;
    final b = _hexBytes(resp);
    // Expected reply: 41 0C A B  → RPM = ((A*256)+B)/4
    final idx = b.indexWhere((v) => v == 0x0C);
    if (idx == -1 || idx + 2 >= b.length) return null;
    return ((b[idx + 1] * 256) + b[idx + 2]) ~/ 4;
  }

  int? _parseSingleByte(String? resp, {int offset = 0}) {
    if (resp == null) return null;
    final b = _hexBytes(resp);
    if (b.length < 3) return null;
    return b.last + offset;
  }

  int? _parseThrottle(String? resp) {
    if (resp == null) return null;
    final b = _hexBytes(resp);
    if (b.isEmpty) return null;
    return (b.last * 100) ~/ 255;
  }

  double? _parseVoltage(String? resp) {
    if (resp == null) return null;
    // ATRV typically replies like "12.6V"
    final match = RegExp(r'([\d.]+)V').firstMatch(resp);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  List<DtcInfo> _parseDtcResponse(String resp) {
    final b = _hexBytes(resp);
    // Response format: 43 <code bytes in pairs>
    final codes = <DtcInfo>[];
    var i = 0;
    if (i < b.length && b[i] == 0x43) i++;
    while (i + 1 < b.length) {
      final byte1 = b[i];
      final byte2 = b[i + 1];
      i += 2;
      if (byte1 == 0 && byte2 == 0) continue; // padding
      final code = _decodeDtcBytes(byte1, byte2);
      codes.add(lookupDtc(code));
    }
    return codes;
  }

  String _decodeDtcBytes(int byte1, int byte2) {
    const prefixes = ['P', 'C', 'B', 'U'];
    final prefix = prefixes[(byte1 & 0xC0) >> 6];
    final firstDigit = (byte1 & 0x30) >> 4;
    final rest = (byte1 & 0x0F).toRadixString(16) +
        (byte2 >> 4).toRadixString(16) +
        (byte2 & 0x0F).toRadixString(16);
    return '$prefix$firstDigit${rest.toUpperCase()}';
  }
}
