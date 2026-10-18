import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/barcode_validator.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _handled = false;
  final _scannerController = MobileScannerController(
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ler código de barras')),
    body: Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (_handled) return;
            final value = capture.barcodes.firstOrNull?.rawValue;
            if (value == null || value.isEmpty) return;
            final result = BarcodeValidator.validate(value);
            if (!result.isValid) return;
            _handled = true;
            _showResult(result.gtin);
          },
        ),
        const Positioned(
          left: 24,
          right: 24,
          top: 80,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Aponte a câmera para um código EAN ou UPC. O produto só será preenchido quando uma fonte de dados autorizada estiver configurada.',
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 88,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'barcode-flash',
                onPressed: _scannerController.toggleTorch,
                child: const Icon(Icons.flash_on_outlined),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.small(
                heroTag: 'barcode-camera',
                onPressed: _scannerController.switchCamera,
                child: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _manualCode,
      icon: const Icon(Icons.keyboard_outlined),
      label: const Text('Digitar código'),
    ),
  );

  Future<void> _manualCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Digitar código'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'EAN ou UPC'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null) return;
    final result = BarcodeValidator.validate(code);
    if (!result.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.error!)));
      }
      return;
    }
    _handled = true;
    await _showResult(result.gtin);
  }

  Future<void> _showResult(String value) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Código identificado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(value),
              const SizedBox(height: 12),
              const Text(
                'O catálogo por código de barras ainda não está configurado. Você pode registrar o alimento manualmente e revisar todos os valores.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/nutrition/new?barcode=$value');
                },
                child: const Text('Registrar manualmente'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() => _handled = false);
                },
                child: const Text('Ler outro código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
