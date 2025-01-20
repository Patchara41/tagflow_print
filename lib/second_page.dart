import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';
import 'bluetooth.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  GlobalKey _globalKey = GlobalKey();
  BluetoothPrintPlus _bluetoothPrintPlus = BluetoothPrintPlus.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isScanning = false;
  String status = 'Unknown';

  String shop = '';
  String date = '';
  String startTime = '';
  String finishedTime = '';
  String pcSeq = '';
  String itemNo = '';
  String itemName = '';
  String color = '';
  String qty = '';
  String assyStartDate = '';
  String line = '';
  String spec = '';
  String tagflowId = '';
  String QRcode = '';
  String model_name = '';
  String station = '';
  String rePrint = '';
  String model = '';
  String assyStartTime = '';
  String height_paper = '74';
  String check_by = '-';

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _scanAndConnect(); // เริ่มการสแกนและเชื่อมต่อเมื่อเปิดแอป
    // เพิ่มการตรวจสอบสถานะการเชื่อมต่อแบบ real-time
    _bluetoothPrintPlus.state.listen((state) {
      setState(() {
        _connected = state == BluetoothPrintPlus.connected;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      // ตรวจสอบว่า arguments ยังไม่ถูกตั้งค่า
      setState(() {
        shop = arguments['shop'] ?? 'x';
        date = arguments['date'] ?? 'x';
        startTime = arguments['start_time'] ?? 'x';
        finishedTime = arguments['finished_time'] ?? 'x';
        pcSeq = arguments['pc_seq'] ?? 'x';
        itemNo = arguments['item_no'] ?? 'x';
        itemName = arguments['item_name'] ?? 'x';
        color = arguments['color'] ?? 'x';
        qty = arguments['qty'] ?? 'x';
        assyStartDate = arguments['assyStartDate'] ?? 'x';
        line = arguments['line'] ?? 'x';
        spec = arguments['spec'] ?? 'x';
        tagflowId = arguments['tagflowId'] ?? 'x';
        QRcode = arguments['QRcode'] ?? 'x';
        model_name = arguments['model_name'] ?? 'x';
        station = arguments['station'] ?? 'x';
        rePrint = arguments['rePrint'] ?? 'x';
        assyStartTime = arguments['assyStartTime'] ?? 'x';
        model = arguments['model'] ?? 'x';
        height_paper = arguments['height'] ?? 'x';
        check_by = arguments['check_by'] ?? 'x';
      });
      // ปริ้นค่า argument ทั้งหมด
      print('Arguments received:');
      print('Shop: $shop');
      print('Date: $date');
      print('Start Time: $startTime');
      print('Finished Time: $finishedTime');
      print('PC Seq: $pcSeq');
      print('Item No: $itemNo');
      print('Item Name: $itemName');
      print('Color: $color');
      print('tagflowId: $tagflowId');
      print('QRcode: $QRcode');
    }
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
        if (device.name == 'BT-SPP' || device.address == '00:19:0E:A6:45:DD') {
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
      // ขนาดใหม่เป็นพิกเซล (70mm x 40mm ที่ 300 DPI)
      double heightInMm = double.tryParse(height_paper) ??
          50; // ใช้ค่า default 50.0 mm หากแปลงไม่ได้
      int height_number = int.tryParse(height_paper) ?? 0;
      double targetWidthInMm = 50;
      double targetHeightInMm = 50;
      int targetWidthInPx =
          (targetWidthInMm / 25.4 * 300).toInt(); // ≈ 826 พิกเซล
      int targetHeightInPx =
          (targetHeightInMm / 25.4 * 300).toInt(); // ≈ 472 พิกเซล
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      // สร้างภาพจาก boundary
      ui.Image originalImage = await boundary.toImage(
        pixelRatio: targetWidthInPx / boundary.size.width,
      );
      ByteData? byteData =
          await originalImage.toByteData(format: ui.ImageByteFormat.png);

      Uint8List originalPngBytes = byteData!.buffer.asUint8List();

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
      int height_number = int.tryParse(height_paper) ?? 0;
      final ByteData bytes = await File(filePath)
          .readAsBytes()
          .then((value) => ByteData.view(value.buffer));
      final Uint8List image = bytes.buffer.asUint8List();

      final TscCommand tscCommand = TscCommand();
      await tscCommand.cleanCommand();
      await tscCommand.cls();
      await tscCommand.size(
          width: 76, // ความกว้างคงที่ 76mm
          height: height_number); // ความสูง 0 เพื่อให้ปรับขนาดอัตโนมัติ

      await tscCommand.image(image: image, x: 0, y: 0); // พิมพ์รูปภาพ
      await tscCommand.print(1);
      final cmd = await tscCommand.getCommand();

      if (cmd != null) {
        await _bluetoothPrintPlus.write(cmd);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('พิมพ์รูปภาพจากไฟล์สำเร็จ')),
        );

        // รอสักครู่ก่อนที่จะ pop
        await Future.delayed(const Duration(milliseconds: 500));

        // ย้อนกลับหนึ่งหน้า
        if (context.mounted) {
          // เช็คว่า context ยังคงอยู่
          Navigator.pop(context);
        }
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
              height: 410,
              color: Colors.white,
              child: CustomPaint(
                painter: LabelPainter(
                    status: status,
                    shop: shop,
                    date: date,
                    startTime: startTime,
                    finishedTime: finishedTime,
                    pcSeq: pcSeq,
                    itemNo: itemNo,
                    itemName: itemName,
                    color: color,
                    qty: qty,
                    assyStartDate: assyStartDate,
                    line: line,
                    spec: spec,
                    tagflowId: tagflowId,
                    QRcode: QRcode,
                    model_name: model_name,
                    station: station,
                    rePrint: rePrint,
                    assyStartTime: assyStartTime,
                    model: model,
                    height_paper: height_paper,
                    check_by: check_by),
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
  final String status;
  final String shop;
  final String date;
  final String startTime;
  final String finishedTime;
  final String pcSeq;
  final String itemNo;
  final String itemName;
  final String color;
  final String qty;
  final String assyStartDate;
  final String line;
  final String spec;
  final String tagflowId;
  final String QRcode;
  final String model_name;
  final String station;
  final String rePrint;
  final String assyStartTime;
  final String model;
  final String height_paper;
  final String check_by;
  LabelPainter(
      {required this.status,
      required this.shop,
      required this.date,
      required this.startTime,
      required this.finishedTime,
      required this.pcSeq,
      required this.itemNo,
      required this.itemName,
      required this.color,
      required this.qty,
      required this.assyStartDate,
      required this.line,
      required this.spec,
      required this.tagflowId,
      required this.QRcode,
      required this.model_name,
      required this.station,
      required this.rePrint,
      required this.assyStartTime,
      required this.model,
      required this.height_paper,
      required this.check_by});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    // วาดกรอบและเส้นแบ่ง
    // canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // กำหนดข้อความต่าง ๆ ตามตัวอย่าง
    final textStyle = TextStyle(color: Colors.black, fontSize: 14);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // วาดข้อความ Title "Tag Flow"
    textPainter.text = TextSpan(
        text: 'Tag Flow',
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 22));
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 10));

    // วาดข้อความอื่น ๆ ตามภาพตัวอย่าง เช่น PO, Shop, Date, Item No., Assy Line เป็นต้น
    _drawText(canvas, textPainter, rePrint, 310, 10, fontSize: 16);
    _drawText(canvas, textPainter, 'เทียบเฉดสีแล้ว', 10, 50, fontSize: 14);
    _drawText(canvas, textPainter, 'PO:', 155, 50, fontSize: 14);
    _drawText(canvas, textPainter, 'PC. Seq', 310, 50, fontSize: 14);
    _drawText(canvas, textPainter, 'Shop :  $shop', 10, 80, fontSize: 14);
    _drawText(canvas, textPainter, 'Start time: $startTime', 155, 80,
        fontSize: 14);
    _drawText(canvas, textPainter, pcSeq, 310, 90, fontSize: 30, isBold: true);
    _drawText(canvas, textPainter, 'Date', 10, 110, fontSize: 14);
    _drawText(canvas, textPainter, date, 50, 110, fontSize: 14);
    _drawText(canvas, textPainter, 'Finished time: ', 155, 110, fontSize: 14);
    _drawText(canvas, textPainter, 'Item No. $itemNo', 10, 140,
        fontSize: 20, isBold: true);
    _drawText(canvas, textPainter, 'Item Name. $itemName', 10, 168,
        fontSize: 20, isBold: true);
    _drawText(canvas, textPainter, 'Color : $color', 10, 198,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, "Q'ty : ", 200, 198,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, qty, 280, 198, fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, "PCS.", 320, 198,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, "Start Date : $assyStartDate", 10, 230,
        fontSize: 14, isBold: true);
    _drawText(canvas, textPainter, "Check By", 200, 228,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, check_by, 285, 228,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, "Assy Line : $line", 10, 260, fontSize: 14);
    _drawText(canvas, textPainter, "ST : $station", 160, 260,
        fontSize: 18, isBold: true);
    _drawText(canvas, textPainter, "Spec : $spec", 270, 260, fontSize: 14);

    _drawText(canvas, textPainter, "Model Code", 298, 140, fontSize: 14);
    _drawText(canvas, textPainter, model, 315, 164, fontSize: 20, isBold: true);

    _drawText(canvas, textPainter, "Inspector Check", 10, 225 + 30 + 30 + 8,
        fontSize: 14);

    // QR Code
    final qrCodePainter = QrPainter(
      data: QRcode,
      version: QrVersions.auto,
      gapless: false,
    );

    drawCustomLine(
      canvas,
      x1: 5,
      y1: 0,
      x2: size.width,
      y2: 0,
      strokeWidth: 1,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 1 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 45,
      x2: 110,
      y2: 75,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 110,
      y1: 45,
      x2: 150,
      y2: 75,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 150,
      y1: 45,
      x2: 290,
      y2: 75,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );
    drawTransparentRectangle(
      canvas,
      x1: 290,
      y1: 45,
      x2: 380,
      y2: 75,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 2 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 75,
      x2: 150,
      y2: 105,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );
    drawTransparentRectangle(
      canvas,
      x1: 150,
      y1: 75,
      x2: 290,
      y2: 105,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );
    drawTransparentRectangle(
      canvas,
      x1: 290,
      y1: 75,
      x2: 380,
      y2: 135,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 3 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 105,
      x2: 45,
      y2: 135,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 45,
      y1: 105,
      x2: 150,
      y2: 135,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 150,
      y1: 105,
      x2: 290,
      y2: 135,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 4 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 135,
      x2: 380,
      y2: 195,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 290,
      y1: 135,
      x2: 380,
      y2: 195,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 290,
      y1: 135,
      x2: 380,
      y2: 160,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 5 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 195,
      x2: 190,
      y2: 225,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    drawTransparentRectangle(
      canvas,
      x1: 190,
      y1: 195,
      x2: 380,
      y2: 225,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 6 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 190,
      y1: 225,
      x2: 380,
      y2: 225 + 30,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE 7 -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 5,
      y1: 195,
      x2: 380,
      y2: 225 + 30 + 30,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // --------------------------- LINE INSPECTOR CHECK  -----------------------------
    drawTransparentRectangle(
      canvas,
      x1: 10,
      y1: 225 + 30 + 30 + 30,
      x2: 260,
      y2: 225 + 30 + 30 + 20 + 80,
      strokeWidth: 1.0,
      color: const ui.Color.fromARGB(255, 0, 0, 0),
    );

    // วาด QR Code ที่มุมขวาล่าง
    canvas.save();
    canvas.translate(
        size.width - 120, size.height - 110); // ขยับ Canvas ไปที่มุมขวาล่าง
    qrCodePainter.paint(canvas, Size(100, 100)); // วาด QR Code ขนาด 100x100
    canvas.restore();
  }

  void _drawText(
      Canvas canvas, TextPainter textPainter, String text, double x, double y,
      {bool isBold = false, double fontSize = 14.0}) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: 400);
    textPainter.paint(canvas, Offset(x, y));
  }

  void drawTransparentRectangle(
    Canvas canvas, {
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    double strokeWidth = 1.0,
    Color color = Colors.black,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke; // กำหนดสไตล์เป็น stroke เพื่อวาดเฉพาะกรอบ

    // สร้างกรอบสี่เหลี่ยมจากจุด (x1, y1) ไปยัง (x2, y2)
    final rect = Rect.fromLTRB(x1, y1, x2, y2);
    canvas.drawRect(rect, paint);
  }

  void drawCustomLine(
    Canvas canvas, {
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    double strokeWidth = 1.0,
    Color color = Colors.black,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // วาดเส้นจากจุด (x1, y1) ไปถึง (x2, y2)
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
