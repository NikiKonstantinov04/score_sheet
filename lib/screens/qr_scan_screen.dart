import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _hasScanned = false; // флаг срещу многократно засичане

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
      case AppLifecycleState.paused:
        controller.stop();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  /// Обработва сканиран код – само първият се взема предвид.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return; // вече сканирахме – игнорираме
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    // Маркираме, че сме сканирали, и спираме камерата
    _hasScanned = true;
    await controller.stop();

    if (!mounted) return;
    Navigator.of(context).pop(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканирайте QR код')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Няма достъп до камерата.\nМоля, разрешете достъп от настройките.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Отвори настройки'),
              ),
            ],
          ),
        ),
      )
          : MobileScanner(
        controller: controller,
        onDetect: _onDetect,
      ),
    );
  }
}