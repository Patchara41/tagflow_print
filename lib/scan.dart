import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: MobileScanner(
        onDetect: (barcode, args) {
          if (barcode.rawValue != null && !isScanned) {
            setState(() {
              isScanned = true;
            });
            String scannedCode = barcode.rawValue!;
            Navigator.pop(context, scannedCode); // ส่งค่ากลับไปยังหน้า HomePage
          }
        },
      ),
    );
  }
}
