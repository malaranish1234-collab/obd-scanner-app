import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Handles the raw Bluetooth Classic SPP link to an ELM327-based
/// OBD-II adapter (e.g. Xsentuals "OBD Advanced").
class ObdBluetoothService {
  BluetoothConnection? _connection;
  final StreamController<String> _lineController =
      StreamController<String>.broadcast();
  final StringBuffer _rxBuffer = StringBuffer();

  Stream<String> get responses => _lineController.stream;

  bool get isConnected => _connection?.isConnected ?? false;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connection = await BluetoothConnection.toAddress(device.address);
    _connection!.input!
        .map((data) => utf8.decode(data, allowMalformed: true))
        .listen(_onData, onDone: () {
      _lineController.add('__DISCONNECTED__');
    });
  }

  void _onData(String chunk) {
    _rxBuffer.write(chunk);
    if (chunk.contains('>')) {
      final full = _rxBuffer.toString();
      _rxBuffer.clear();
      _lineController.add(full);
    }
  }

  Future<String> sendCommand(String command,
      {Duration timeout = const Duration(seconds: 5)}) async {
    if (_connection == null || !_connection!.isConnected) {
      throw StateError('Not connected to OBD adapter');
    }
    final completer = Completer<String>();
    late StreamSubscription sub;
    sub = responses.listen((line) {
      if (line == '__DISCONNECTED__') {
        sub.cancel();
        if (!completer.isCompleted) {
          completer.completeError(StateError('Adapter disconnected'));
        }
        return;
      }
      sub.cancel();
      if (!completer.isCompleted) completer.complete(line);
    });

    _connection!.output.add(utf8.encode('$command\r'));
    await _connection!.output.allSent;

    return completer.future.timeout(timeout, onTimeout: () {
      sub.cancel();
      throw TimeoutException('No response for command: $command');
    });
  }

  Future<void> disconnect() async {
    await _connection?.finish();
    _connection = null;
  }

  void dispose() {
    _lineController.close();
    _connection?.dispose();
  }
}
