import 'package:flutter/material.dart';
import 'screens/connect_screen.dart';

void main() {
  runApp(const ObdScannerApp());
}

class ObdScannerApp extends StatelessWidget {
  const ObdScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Diagnostic Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const ConnectScreen(),
    );
  }
}
