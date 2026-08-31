import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/obd_service.dart';
import 'dtc_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ObdBluetoothService bt;
  final ObdService obd;
  const DashboardScreen({super.key, required this.bt, required this.obd});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  VehicleSnapshot? _snapshot;
  Timer? _pollTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    try {
      final snap = await widget.obd.readLiveSnapshot();
      if (mounted) setState(() {
        _snapshot = snap;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Read error: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    widget.bt.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Vehicle Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'Fault Codes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DtcScreen(obd: widget.obd),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _MetricCard(label: 'RPM', value: s?.rpm?.toString() ?? '--'),
            _MetricCard(
                label: 'Speed', value: '${s?.speedKmh ?? '--'} km/h'),
            _MetricCard(
                label: 'Coolant Temp',
                value: '${s?.coolantTempC ?? '--'} °C'),
            _MetricCard(
                label: 'Battery Voltage',
                value: s?.batteryVoltage != null
                    ? '${s!.batteryVoltage!.toStringAsFixed(1)} V'
                    : '--',
                warn: (s?.batteryVoltage ?? 12.6) < 11.5),
            _MetricCard(
                label: 'Throttle', value: '${s?.throttlePercent ?? '--'} %'),
          ],
        ),
      ),
      bottomNavigationBar: _error != null
          ? Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(_error!, textAlign: TextAlign.center),
            )
          : null,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;
  const _MetricCard(
      {required this.label, required this.value, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: warn ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: warn ? Colors.red : null)),
          ],
        ),
      ),
    );
  }
}
