import 'package:flutter/material.dart';

/// Zaślepka filmu, którego nie da się odtworzyć (zły URL, brak sieci).
class VideoError extends StatelessWidget {
  const VideoError({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 48),
          SizedBox(height: 8),
          Text('Nie udało się odtworzyć filmu',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

/// Komunikat o nieudanym wczytaniu z przyciskiem „Odśwież".
/// [compact] = pasek nad treścią zamiast widoku na cały ekran.
class LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const LoadError({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: double.infinity,
        color: Colors.red.shade50,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade700)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Odśwież')),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Odśwież'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
