import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ler código de barras')),
    body: Stack(children: [
      MobileScanner(
        controller: MobileScannerController(
          formats: const [BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.upcA, BarcodeFormat.upcE],
        ),
        onDetect: (capture) {
          if (_handled) return;
          final value = capture.barcodes.firstOrNull?.rawValue;
          if (value == null || value.isEmpty) return;
          _handled = true;
          _showResult(value);
        },
      ),
      const Positioned(
        left: 24, right: 24, top: 80,
        child: Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Aponte a câmera para um código EAN ou UPC. O produto só será preenchido quando uma fonte de dados autorizada estiver configurada.'))),
      ),
    ]),
  );

  Future<void> _showResult(String value) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Código identificado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(value),
          const SizedBox(height: 12),
          const Text('O catálogo por código de barras ainda não está configurado. Você pode registrar o alimento manualmente e revisar todos os valores.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () { Navigator.pop(sheetContext); context.go('/nutrition/new?barcode=$value'); }, child: const Text('Registrar manualmente')),
          TextButton(onPressed: () { Navigator.pop(sheetContext); setState(() => _handled = false); }, child: const Text('Ler outro código')),
        ]),
      )),
    );
  }
}
