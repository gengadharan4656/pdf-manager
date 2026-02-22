import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isScanning = true;
  String? _scannedResult;
  String? _scannedFormat;
  final List<_ScanRecord> _scanHistory = [];
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startScanner();
  }

  void _startScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.pdf417,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.aztec,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.stop();
    } else if (state == AppLifecycleState.resumed && _isScanning) {
      _controller?.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    HapticFeedback.mediumImpact();
    _controller?.stop();

    setState(() {
      _scannedResult = barcode.rawValue!;
      _scannedFormat = barcode.format.name.toUpperCase();
      _isScanning = false;
      _scanHistory.insert(
        0,
        _ScanRecord(value: barcode.rawValue!,
            format: barcode.format.name.toUpperCase(), time: DateTime.now()),
      );
    });
  }

  void _resetScan() {
    setState(() { _isScanning = true; _scannedResult = null; });
    _controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.qr_code_scanner, size: 22),
          SizedBox(width: 8),
          Text('Barcode Scanner'),
        ]),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? Colors.yellow : Colors.white),
            onPressed: () { _controller?.toggleTorch(); setState(() => _torchOn = !_torchOn); },
          ),
          if (!_isScanning)
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _resetScan),
        ],
      ),
      body: Column(children: [
        Expanded(flex: 3, child: _isScanning
            ? Stack(children: [
          MobileScanner(controller: _controller!, onDetect: _onDetect),
          Center(child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(12)),
          )),
        ])
            : Container(
          color: Colors.green.shade50,
          child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 56),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SelectableText(_scannedResult ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const SizedBox(height: 4),
              Text(_scannedFormat ?? '', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _scannedResult!));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')));
                    },
                    icon: const Icon(Icons.copy, size: 16), label: const Text('Copy')),
                const SizedBox(width: 12),
                ElevatedButton.icon(onPressed: _resetScan,
                    icon: const Icon(Icons.refresh, size: 16), label: const Text('Scan Again')),
              ]),
            ],
          )),
        )
        ),
        if (_scanHistory.isNotEmpty) Expanded(flex: 2, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('History (${_scanHistory.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () => setState(() => _scanHistory.clear()),
                      child: const Text('Clear')),
                ])),
            Expanded(child: ListView.builder(
              itemCount: _scanHistory.length,
              itemBuilder: (_, i) => ListTile(dense: true,
                leading: const Icon(Icons.qr_code, size: 18),
                title: Text(_scanHistory[i].value, maxLines: 1,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                subtitle: Text(_scanHistory[i].format),
                trailing: IconButton(icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => Clipboard.setData(ClipboardData(text: _scanHistory[i].value))),
              ),
            )),
          ],
        )),
      ]),
    );
  }
}

class _ScanRecord {
  final String value;
  final String format;
  final DateTime time;
  _ScanRecord({required this.value, required this.format, required this.time});
}