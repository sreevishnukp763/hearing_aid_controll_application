import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Hearing Aid Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BLEScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}




