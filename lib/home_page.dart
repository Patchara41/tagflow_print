import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: (message) async {
          // รับข้อความจาก JavaScript
          String action = message.message.split('!')[0];
          if (action == 'clicked') {
            // เมื่อกดปุ่ม ให้ไปที่หน้าที่สองพร้อมกับพารามิเตอร์
            Navigator.pushNamed(
              context,
              '/second',
              arguments: {
                'shop': message.message.split('!')[1],
                'date': message.message.split('!')[2],
                'start_time': message.message.split('!')[3],
                'finished_time': message.message.split('!')[4],
                'pc_seq': message.message.split('!')[5],
                'item_no': message.message.split('!')[6],
                'item_name': message.message.split('!')[7],
                'color': message.message.split('!')[8],
                'qty': message.message.split('!')[9],
                'assyStartDate': message.message.split('!')[10],
                'line': message.message.split('!')[11],
                'spec': message.message.split('!')[12],
                'tagflowId': message.message.split('!')[13],
                'QRcode': message.message.split('!')[14],
                'model_name': message.message.split('!')[15],
                'station': message.message.split('!')[16],
                'rePrint': message.message.split('!')[17],
                'assyStartTime': message.message.split('!')[18],
                'model': message.message.split('!')[19],
                'check_by': message.message.split('!')[20],
                'height': message.message.split('!')[21],
              },
            );
          } else if (action == 'scan') {
            // เปิดหน้า ScanPage
            final scannedCode = await Navigator.pushNamed(context, '/scan');
            if (scannedCode != null) {
              // อัปเดต URL ใน WebView
              String newUrl =
                  'https://portal.yamaha-motor.co.th/e-learning-assy/stock-plpt/scan_in.php?qrcode=$scannedCode';
              controller.loadRequest(Uri.parse(newUrl));
            }
          }
        },
      )
      ..loadRequest(Uri.parse(
          'https://portal.yamaha-motor.co.th/e-learning-assy/stock-plpt/select_seq.php'));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ตรวจสอบว่า WebView สามารถย้อนกลับได้หรือไม่
        if (await controller.canGoBack()) {
          controller.goBack(); // ย้อนกลับใน WebView
          return false; // ไม่ปิดแอป
        } else {
          return true; // ปิดแอป
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(controller: controller),
        ),
      ),
    );
  }
}
