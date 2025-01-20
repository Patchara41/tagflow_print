import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';
import 'bluetooth.dart'; // หน้าสำหรับการเชื่อมต่อ Bluetooth

void main() {
  runApp(MaterialApp(home: CreateImagePage()));
}

class CreateImagePage extends StatefulWidget {
  @override
  _CreateImagePageState createState() => _CreateImagePageState();
}

class _CreateImagePageState extends State<CreateImagePage> {
  GlobalKey _globalKey = GlobalKey();
  BluetoothPrintPlus _bluetoothPrintPlus = BluetoothPrintPlus.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _scanAndConnect(); // เริ่มการสแกนและเชื่อมต่อเมื่อเปิดแอป
  }

  // ฟังก์ชันสำหรับการสแกนหาอุปกรณ์และเชื่อมต่ออัตโนมัติ
  void _scanAndConnect() {
    _bluetoothPrintPlus.startScan(timeout: Duration(seconds: 4));
    _bluetoothPrintPlus.scanResults.listen((results) {
      setState(() {
        _devices = results;
      });
      // หาอุปกรณ์ที่ต้องการจากชื่อและ MacAddress
      for (var device in results) {
        if (device.name == 'BT-SPP' && device.address == '00:19:0E:A6:45:DD') {
          _connect(device); // เชื่อมต่ออัตโนมัติ
        }
      }
    });
  }

  // ตรวจสอบสถานะการเชื่อมต่อ Bluetooth
  void _checkBluetoothStatus() async {
    _bluetoothPrintPlus.state.listen((state) {
      setState(() {
        if (state == BluetoothPrintPlus.connected) {
          _connected = true;
        } else {
          _connected = false;
          _selectedDevice = null;
        }
      });
    });
  }

  Future<void> _saveImageAndPrint() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      // สร้างภาพจาก boundary
      ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await originalImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List originalPngBytes = byteData!.buffer.asUint8List();

      // ขนาดใหม่เป็นพิกเซล (70mm x 40mm ที่ 300 DPI)
      double targetWidthInMm = 50;
      double targetHeightInMm = 65;
      int targetWidthInPx =
          (targetWidthInMm / 25.4 * 300).toInt(); // ≈ 826 พิกเซล
      int targetHeightInPx =
          (targetHeightInMm / 25.4 * 300).toInt(); // ≈ 472 พิกเซล

      // สร้างภาพที่ปรับขนาดแล้ว
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);
      Paint paint = Paint();

      // วาดภาพที่ปรับขนาดลงบน canvas
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
            originalImage.height.toDouble()),
        Rect.fromLTWH(
            0, 0, targetWidthInPx.toDouble(), targetHeightInPx.toDouble()),
        paint,
      );

      // แปลง canvas ให้เป็น ui.Image ใหม่
      ui.Image resizedImage = await recorder
          .endRecording()
          .toImage(targetWidthInPx, targetHeightInPx);

      ByteData? resizedByteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedPngBytes = resizedByteData!.buffer.asUint8List();

      // บันทึกลงไฟล์ในเครื่อง
      final directory = (await getApplicationDocumentsDirectory()).path;
      String filePath = '$directory/label_image.png';
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(resizedPngBytes);

      print('บันทึกรูปภาพเรียบร้อยที่: $filePath');

      // พิมพ์รูปภาพที่บันทึก
      _printImageFromFile(filePath);
    } catch (e) {
      print('เกิดข้อผิดพลาดในการบันทึกรูปภาพ: $e');
    }
  }

  // ฟังก์ชันการพิมพ์รูปภาพจากไฟล์ โดยปรับขนาดลง 30%
  void _printImageFromFile(String filePath) async {
    try {
      final ByteData bytes = await File(filePath)
          .readAsBytes()
          .then((value) => ByteData.view(value.buffer));
      final Uint8List image = bytes.buffer.asUint8List();

      final TscCommand tscCommand = TscCommand();
      await tscCommand.cleanCommand();
      await tscCommand.cls();
      // ลดขนาดเป็น 30%
      await tscCommand.size(
          width: (76 * 1).toInt(),
          height: (40 * 3).toInt()); // ขนาดฉลาก 76x40mm ลดลง 30%
      await tscCommand.image(image: image, x: 0, y: 0); // พิมพ์รูปภาพ
      await tscCommand.print(1);
      final cmd = await tscCommand.getCommand();

      if (cmd != null) {
        await _bluetoothPrintPlus.write(cmd);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('พิมพ์รูปภาพจากไฟล์สำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถสร้างคำสั่งพิมพ์ได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาดในการพิมพ์รูปภาพ: ${e.toString()}')),
      );
    }
  }

  // ฟังก์ชันสำหรับเชื่อมต่อกับอุปกรณ์ Bluetooth
  void _connect(BluetoothDevice device) async {
    setState(() {
      _selectedDevice = device;
    });
    try {
      await _bluetoothPrintPlus.connect(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อกับอุปกรณ์ ${device.name} สำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อไม่สำเร็จ: ${e.toString()}')),
      );
    }
  }

  // ฟังก์ชันสำหรับยกเลิกการเชื่อมต่อ Bluetooth
  void _disconnect() async {
    try {
      await _bluetoothPrintPlus.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยกเลิกการเชื่อมต่อแล้ว')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการยกเลิกการเชื่อมต่อ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Tag Flow'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: 400,
              height: 450,
              color: Colors.white,
              child: CustomPaint(
                painter: LabelPainter(),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _saveImageAndPrint,
                child: Text('Print'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BluetoothPage()),
                  );
                },
                child: Text('Bluetooth'),
              ),
              SizedBox(width: 10),
              if (_connected)
                ElevatedButton(
                  onPressed: _disconnect,
                  child: Text('Disconnect'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// CustomPainter สำหรับการวาดข้อความและ QR Code ตามตัวอย่างรูปภาพ
class LabelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    // วาดกรอบและเส้นแบ่ง
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // กำหนดข้อความต่าง ๆ ตามตัวอย่าง
    final textStyle = TextStyle(color: Colors.black, fontSize: 14);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // วาดข้อความ Title "Tag Flow"
    textPainter.text = TextSpan(
        text: 'Tag Flow',
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 20));
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 10));

    // วาดข้อความอื่น ๆ ตามภาพตัวอย่าง เช่น PO, Shop, Date, Item No., Assy Line เป็นต้น
    _drawText(canvas, textPainter, 'เทียบเฉดสีแล้ว    PO:', 10, 50);
    _drawText(canvas, textPainter, 'PC. Seq. A28', size.width - 100, 50);
    _drawText(canvas, textPainter, 'Shop : 9224', 10, 80);
    _drawText(canvas, textPainter, 'Start time: ', 200, 80);
    _drawText(canvas, textPainter, 'Date : 31/07/2024', 10, 110);
    _drawText(canvas, textPainter, 'Finished time: 8:30', 200, 110);
    _drawText(canvas, textPainter, 'Item No.  BJK-XF83U-00-UJ-80', 10, 140);
    _drawText(
        canvas, textPainter, 'Item Name.  BODY LEG SHIELD SUB ASSY', 10, 170);
    // QR Code
    final qrCodePainter = QrPainter(
      data: 'A28|9224|BODY LEG SHIELD SUB ASSY',
      version: QrVersions.auto,
      gapless: false,
    );

    // วาด QR Code ที่มุมขวาล่าง
    canvas.save();
    canvas.translate(
        size.width - 120, size.height - 120); // ขยับ Canvas ไปที่มุมขวาล่าง
    qrCodePainter.paint(canvas, Size(100, 100)); // วาด QR Code ขนาด 100x100
    canvas.restore();
  }

  void _drawText(
      Canvas canvas, TextPainter textPainter, String text, double x, double y) {
    textPainter.text = TextSpan(
        text: text, style: TextStyle(color: Colors.black, fontSize: 14));
    textPainter.layout(minWidth: 0, maxWidth: 400);
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
