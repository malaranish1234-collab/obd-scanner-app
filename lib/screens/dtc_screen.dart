import 'package:flutter/material.dart';
import '../services/obd_service.dart';
import '../models/dtc_database.dart';

class DtcScreen extends StatefulWidget {
  final ObdService obd;
  const DtcScreen({super.key, required this.obd});

  @override
  State<DtcScreen> createState() => _DtcScreenState();
}

class _DtcScreenState extends State<DtcScreen> {
  List<DtcInfo> _codes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final codes = await widget.obd.readFaultCodes();
      setState(() => _codes = codes);
    } catch (e) {
      setState(() => _error = 'Scan failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Fault Codes?'),
        content: const Text(
            'This will erase all stored fault codes and turn off the '
            'check-engine indicator. Only do this after fixing the issue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.obd.clearFaultCodes();
      _scan();
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fault Codes'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _scan),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: (_loading || _codes.isEmpty) ? null : _confirmClear),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _codes.isEmpty
                  ? const Center(
                      child: Text('No fault codes found. Vehicle looks healthy.'))
                  : ListView.builder(
                      itemCount: _codes.length,
                      itemBuilder: (ctx, i) {
                        final c = _codes[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _severityColor(c.severity),
                              child: Text(c.severity[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text('${c.code} — ${c.title}'),
                            subtitle: Text(c.plainLanguage),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
