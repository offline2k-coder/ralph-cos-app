import 'package:flutter/material.dart';

class TacticalCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? accentColor;
  final IconData? icon;
  final List<Widget>? actions;

  const TacticalCard({
    super.key,
    required this.title,
    required this.child,
    this.accentColor,
    this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeAccent = accentColor ?? Colors.deepOrange.shade300;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: themeAccent, size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: themeAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class TacticalChecklist extends StatelessWidget {
  final List<String> items;
  final Color? bulletColor;

  const TacticalChecklist({
    super.key,
    required this.items,
    this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeBullet = bulletColor ?? Colors.red.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '▪ ',
                style: TextStyle(
                  color: themeBullet,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
