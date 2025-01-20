import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothPrintPlus _bluetoothPrintPlus = BluetoothPrintPlus.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

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

  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });
    _bluetoothPrintPlus.startScan(timeout: Duration(seconds: 4));
    _bluetoothPrintPlus.scanResults.listen((results) {
      setState(() {
        _devices = results;
      });
    });
    Future.delayed(Duration(seconds: 4), () {
      setState(() {
        _isScanning = false;
      });
    });
  }

  void _connect(BluetoothDevice device) async {
    setState(() {
      _selectedDevice = device;
    });
    try {
      await _bluetoothPrintPlus.connect(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อกับอุปกรณ์สำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อไม่สำเร็จ: ${e.toString()}')),
      );
    }
  }

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

  void _testPrintBarcode() async {
    // ฟังก์ชันการพิมพ์ Barcode 123456789
    final TscCommand tscCommand = TscCommand();
    await tscCommand.size(width: 76, height: 40);
    await tscCommand.cls();
    await tscCommand.barCode(content: "123456789", x: 10, y: 10);
    await tscCommand.print(1);
    final cmd = await tscCommand.getCommand();

    if (cmd != null) {
      await _bluetoothPrintPlus.write(cmd);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('พิมพ์ Barcode สำเร็จ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถพิมพ์ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เชื่อมต่อ Bluetooth'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startScan,
            child: Text(_isScanning ? 'กำลังค้นหา...' : 'ค้นหาอุปกรณ์'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? 'ไม่มีชื่อ'),
                  subtitle: Text(_devices[index].address ?? ''),
                  trailing: ElevatedButton(
                    onPressed:
                        _connected ? null : () => _connect(_devices[index]),
                    child: Text(_connected ? 'เชื่อมต่อแล้ว' : 'เชื่อมต่อ'),
                  ),
                );
              },
            ),
          ),
          if (_connected)
            Column(
              children: [
                ElevatedButton(
                  onPressed: _testPrintBarcode,
                  child: Text('ทดสอบการพิมพ์ Barcode'),
                ),
                ElevatedButton(
                  onPressed: _disconnect,
                  child: Text('ยกเลิกการเชื่อมต่อ'),
                ),
              ],
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // กลับไปหน้า main.dart
            },
            child: Text('กลับไปหน้าแสดงรูปภาพ'),
          ),
        ],
      ),
    );
  }
}
