import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/database_service.dart';
import '../services/gps_service.dart';
import '../widgets/qr_scanner_widget.dart';

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final TextEditingController _learnedController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _classSessionQR;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;
  DateTime? _locationTimestamp;

  @override
  void dispose() {
    _learnedController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  // ── Step 1: GPS capture ──────────────────────────────────────────────────

  Future<void> _captureGps() async {
    setState(() {
      _isLocating = true;
      _latitude = null;
      _longitude = null;
      _locationTimestamp = null;
    });
    try {
      final location = await GpsService.capture();
      if (!mounted) return;
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _locationTimestamp = location.timestamp;
        _isLocating = false;
      });
    } on GpsServiceException catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ── Step 2: QR scan ──────────────────────────────────────────────────────

  Future<void> _openQrScanner() async {
    final qrValue = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const QRScannerWidget()),
    );
    if (!mounted) return;
    if (qrValue != null) {
      setState(() => _classSessionQR = qrValue);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Session QR: $qrValue')));
    }
  }

  // ── Validation + save ────────────────────────────────────────────────────

  Future<void> _onComplete() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please capture your GPS location first.'),
        ),
      );
      return;
    }
    if (_classSessionQR == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please scan the session QR code first.'),
        ),
      );
      return;
    }
    await _showConfettiSuccess();
  }

  Future<void> _showConfettiSuccess() async {
    final lastId = DatabaseService.lastCheckInId;
    if (!kIsWeb && lastId != null) {
      await DatabaseService.instance.saveCheckOut(
        id: lastId,
        data: {
          'checkout_time': DateTime.now().toIso8601String(),
          'checkout_lat': _latitude ?? 0.0,
          'checkout_lng': _longitude ?? 0.0,
          'qr_checkout': _classSessionQR ?? '',
          'learned_today': _learnedController.text.trim(),
          'feedback': _instructorController.text.trim(),
        },
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text('🎉 Class session completed and saved!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    // ── Navigation: FinishClassScreen → back to HomeScreen ──────────────
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header icon ───────────────────────────────────────────
              Center(
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.task_alt_rounded,
                      size: 64, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Wrap up your class',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a minute to reflect and close the session.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              // ── Step 1: GPS ───────────────────────────────────────────
              _SectionLabel(label: 'Step 1 — Capture Location'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isLocating ? null : _captureGps,
                icon: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_isLocating
                    ? 'Locating...'
                    : _latitude != null
                        ? 'Location Captured ✓'
                        : 'Capture GPS Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
              if (_latitude != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                          'Lng: ${_longitude!.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('At: $_locationTimestamp',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // ── Step 2: QR scan ───────────────────────────────────────
              _SectionLabel(label: 'Step 2 — Scan Session QR'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(_classSessionQR != null
                    ? 'Session QR Scanned ✓'
                    : 'Scan to Close Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  side: BorderSide(color: colorScheme.secondary),
                ),
              ),
              const SizedBox(height: 20),
              // ── Step 3: Reflection ────────────────────────────────────
              _SectionLabel(label: 'Step 3 — Reflection'),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _learnedController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'What I learned today',
                        hintText:
                            'Write key concepts or takeaways from today\'s class',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Please describe what you learned today.'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructorController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructor feedback (optional)',
                        hintText: 'Any quick note for the instructor',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onComplete,
            child: const Text('Complete'),
          ),
        ),
      ),
    );
  }
}

// ── Private widget ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
