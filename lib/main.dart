import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';
import 'second_page.dart';
import 'scan.dart'; // เพิ่มการ import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check and request Bluetooth permissions
  await _checkAndRequestBluetoothPermissions();

  runApp(MyApp());
}

Future<void> _checkAndRequestBluetoothPermissions() async {
  // Check Bluetooth permissions
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
  ].request();

  // Check if any permission was denied
  bool allGranted = true;
  statuses.forEach((permission, status) {
    if (!status.isGranted) {
      allGranted = false;
    }
  });

  if (!allGranted) {
    // You might want to show a dialog here explaining why the permissions are needed
    print('Bluetooth permissions not granted');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/second': (context) => SecondPage(),
        '/scan': (context) => ScanPage(), // เพิ่ม route สำหรับ ScanPage
      },
    );
  }
}
