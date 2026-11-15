import 'package:flutter/material.dart';

import '../constants.dart';

/// Jednolita zaślepka pustej listy (ikona + tytuł + opcjonalny podtytuł).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            if (subtitle != null) ...[
              const SizedBox(height: kGapXs),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
