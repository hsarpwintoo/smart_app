import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/checkin_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/gps_service.dart';
import '../widgets/qr_scanner_widget.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isLocating = false;
  bool _isSubmitting = false;
  int? _selectedMoodIndex;

  double? _latitude;
  double? _longitude;
  DateTime? _locationTimestamp;
  String? _classSessionQR;

  final _formKey = GlobalKey<FormState>();
  String? _moodError;

  final TextEditingController _previousTopicController =
      TextEditingController();
  final TextEditingController _expectedTopicController =
      TextEditingController();

  @override
  void dispose() {
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
  }

  static const List<_MoodOption> _moods = [
    _MoodOption(emoji: '😞', label: 'Low'),
    _MoodOption(emoji: '😕', label: 'Tired'),
    _MoodOption(emoji: '😐', label: 'Neutral'),
    _MoodOption(emoji: '🙂', label: 'Good'),
    _MoodOption(emoji: '😄', label: 'Great'),
  ];

  // ── GPS + QR verification ────────────────────────────────────────────────

  Future<void> _startVerification() async {
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

      // 2. Immediately open the QR scanner after GPS succeeds.
      if (!mounted) return;
      final qrValue = await Navigator.push<String>(
        context,
        MaterialPageRoute<String>(builder: (_) => const QRScannerWidget()),
      );
      if (!mounted) return;
      if (qrValue != null) setState(() => _classSessionQR = qrValue);
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

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;

    // 1. Text field validation.
    final isFormValid = _formKey.currentState!.validate();

    // 2. Mood picker validation.
    if (_selectedMoodIndex == null) {
      setState(() => _moodError = 'Please select a mood.');
    } else {
      setState(() => _moodError = null);
    }

    if (!isFormValid || _selectedMoodIndex == null) return;

    // 3. GPS + QR validation.
    final hasVerification = _latitude != null && _classSessionQR != null;
    if (!hasVerification && !kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content:
              Text('Please capture GPS and scan the class QR first.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final moodScore = _selectedMoodIndex! + 1; // 1-based
    final latitude = _latitude ?? 0.0;
    final longitude = _longitude ?? 0.0;
    final qrCode = (_classSessionQR == null || _classSessionQR!.isEmpty)
        ? 'WEB-MANUAL'
        : _classSessionQR!;

    setState(() => _isSubmitting = true);

    bool localSaved = false;

    try {
      // 4a. Save to local SQLite (skip on web, sqflite is mobile-first).
      if (!kIsWeb) {
        try {
          await DatabaseService.instance.saveCheckIn(
            data: {
              'checkin_time': now.toIso8601String(),
              'checkin_lat': latitude,
              'checkin_lng': longitude,
              'qr_checkin': qrCode,
              'previous_topic': _previousTopicController.text.trim(),
              'expected_topic': _expectedTopicController.text.trim(),
              'mood': moodScore,
            },
          );
          localSaved = true;
        } catch (_) {
          localSaved = false;
        }
      }

      // 4b. Save to Firestore.
      await FirestoreService.instance.saveCheckIn(
        CheckInModel(
          studentId: 'student_001',
          timestamp: now,
          latitude: latitude,
          longitude: longitude,
          qrCode: qrCode,
          previousTopic: _previousTopicController.text.trim(),
          expectedTopic: _expectedTopicController.text.trim(),
          moodScore: moodScore,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            localSaved
                ? '✅ Check-in saved locally + Firestore!'
                : '✅ Check-in saved!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('❌ Save failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── GPS + QR glass card ──────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                _isLocating ? null : _startVerification,
                            icon:
                                const Icon(Icons.qr_code_scanner_rounded),
                            label:
                                const Text('Capture GPS & Scan QR'),
                          ),
                          if (_isLocating) ...[
                            const SizedBox(height: 14),
                            const LinearProgressIndicator(minHeight: 6),
                            const SizedBox(height: 8),
                            Text('Locating…',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                          ],
                          if (_latitude != null) ...[
                            const SizedBox(height: 14),
                            _InfoBadge(
                              icon: Icons.check_circle_rounded,
                              color: colorScheme.primary,
                              lines: [
                                'Location captured',
                                'Lat: ${_latitude!.toStringAsFixed(6)}',
                                'Lng: ${_longitude!.toStringAsFixed(6)}',
                              ],
                            ),
                          ],
                          if (_classSessionQR != null) ...[
                            const SizedBox(height: 10),
                            _InfoBadge(
                              icon: Icons.qr_code_rounded,
                              color: colorScheme.secondary,
                              lines: ['QR: $_classSessionQR'],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // ── Learning reflection fields ──────────────────────────
                Text(
                  'Learning Reflection',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previousTopicController,
                  decoration: const InputDecoration(
                    labelText: 'Previous Topic',
                    hintText: 'What was covered in the last class?',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Previous topic cannot be empty.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expectedTopicController,
                  decoration: const InputDecoration(
                    labelText: 'Expected Topic',
                    hintText: 'What do you expect to learn today?',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Expected topic cannot be empty.'
                      : null,
                ),
                const SizedBox(height: 24),
                // ── Mood picker ─────────────────────────────────────────
                Text(
                  'Mood Picker',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_moods.length, (index) {
                      final mood = _moods[index];
                      final isSelected = _selectedMoodIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: index == _moods.length - 1 ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedMoodIndex = index;
                            _moodError = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: 78,
                            height: isSelected ? 96 : 90,
                            transform: Matrix4.identity()
                              ..scale(isSelected ? 1.04 : 1.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline
                                        .withValues(alpha: 0.25),
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(mood.emoji,
                                    style:
                                        const TextStyle(fontSize: 24)),
                                const SizedBox(height: 6),
                                Text(
                                  mood.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_moodError != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _moodError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
            onPressed: _isSubmitting ? null : _onSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ),
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _MoodOption {
  const _MoodOption({required this.emoji, required this.label});
  final String emoji;
  final String label;
}

/// A small coloured info block used inside the glass card.
class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.color,
    required this.lines,
  });
  final IconData icon;
  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (l) => Text(l,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
