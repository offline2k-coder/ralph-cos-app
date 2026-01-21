import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/streak_provider.dart';
import '../widgets/tactical_button.dart';

class IntegrityCheckWidget extends ConsumerWidget {
  const IntegrityCheckWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.shade900, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.military_tech,
              size: 64,
              color: Colors.deepOrange.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MISSION LOG: INTEGRITY CHECK',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'RALPH demands the TRUTH. Have you completed all levers of power today?',
            style: TextStyle(
              color: Colors.grey.shade400,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TacticalButton(
                  onPressed: () => _confirm(ref, true),
                  icon: Icons.check_circle,
                  label: 'MISSION WON',
                  backgroundColor: Colors.green.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TacticalButton(
                  onPressed: () => _confirm(ref, false),
                  icon: Icons.cancel,
                  label: 'MISSION LOST',
                  backgroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(WidgetRef ref, bool success) {
    ref.read(streakProvider.notifier).completeDay(success);
  }
}
