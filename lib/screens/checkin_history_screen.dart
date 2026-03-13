import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checkin_model.dart';
import '../services/firestore_service.dart';

/// Displays all check-in records from Firestore in real time.
/// Uses a [StreamBuilder] so the list updates automatically whenever new
/// records are written.
class CheckInHistoryScreen extends StatelessWidget {
  const CheckInHistoryScreen({super.key});

  // Mood index → emoji look-up (moodScore 1–5)
  static const List<String> _moodEmojis = ['', '😞', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in History'),
      ),
      body: StreamBuilder<List<CheckInModel>>(
        stream: FirestoreService.instance.getCheckInsStream(),
        builder: (context, snapshot) {
          // ── Loading state ──────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error state ────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load records.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty state ────────────────────────────────────────────────
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No check-ins yet.\nComplete your first check-in!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ── Data list ──────────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = records[index];
              return _CheckInCard(record: record, moodEmojis: _moodEmojis);
            },
          );
        },
      ),
    );
  }
}

// ── Private card widget ──────────────────────────────────────────────────────

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.record,
    required this.moodEmojis,
  });

  final CheckInModel record;
  final List<String> moodEmojis;

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mood = record.moodScore.clamp(1, 5);
    final emoji = moodEmojis[mood];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (mood + time) ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'Mood: $mood $emoji',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(record.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // ── Body info ────────────────────────────────────────────
            _InfoRow(
              label: 'Previous Topic',
              value: record.previousTopic,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Expected Topic',
              value: record.expectedTopic,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
