import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';
import '../services/obd_service.dart';
import 'dashboard_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _bt = ObdBluetoothService();
  List<BluetoothDevice> _devices = [];
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    try {
      final devices = await _bt.getBondedDevices();
      setState(() => _devices = devices);
    } catch (e) {
      setState(() => _status = 'Could not list paired devices: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    setState(() {
      _loading = true;
      _status = 'Connecting to ${device.name ?? device.address}...';
    });
    try {
      await _bt.connect(device);
      final obd = ObdService(_bt);
      setState(() => _status = 'Initializing adapter...');
      await obd.initializeAdapter();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(bt: _bt, obd: obd),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect OBD Scanner')),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pair your OBD-II Bluetooth adapter (e.g. Xsentuals OBD Advanced) '
              'in phone Bluetooth settings first, then select it below.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_status!, textAlign: TextAlign.center),
              ),
            ..._devices.map((d) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(d.name ?? 'Unknown device'),
                    subtitle: Text(d.address),
                    onTap: _loading ? null : () => _connectTo(d),
                  ),
                )),
            if (!_loading && _devices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(
                    child: Text('No paired devices found. Pair your OBD '
                        'adapter in Bluetooth settings, then pull to refresh.')),
              ),
          ],
        ),
      ),
    );
  }
}
