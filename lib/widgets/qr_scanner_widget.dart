import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reusable full-screen QR scanner page.
///
/// Push this as a route. It pops with the scanned [String] value when a
/// barcode is detected, or with null if the user dismisses it.
///
/// Example usage:
/// ```dart
/// final String? classSessionQR = await Navigator.push<String>(
///   context,
///   MaterialPageRoute(builder: (_) => const QRScannerWidget()),
/// );
/// if (classSessionQR != null) { /* store or use classSessionQR */ }
/// ```
class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({super.key});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();

  /// Guard against firing onDetect multiple times for the same frame.
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    _hasScanned = true;
    // Pop and return the scanned value to the caller.
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          // Live camera feed with QR detection.
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Decorative scanner frame overlay.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.secondary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Corner accent marks inside the frame.
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _CornerPainter(color: colorScheme.secondary),
              ),
            ),
          ),

          // Instruction label at the bottom.
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Point the camera at the class QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws short corner marks to enhance the scanner frame.
class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(w, 0), Offset(w - len, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
