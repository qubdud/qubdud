import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Suwak porównania Przed/Po — przeciągnij pionową linię.
class BeforeAfterSlider extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;

  const BeforeAfterSlider({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _fraction = 0.5;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (d) => setState(() =>
              _fraction = (d.localPosition.dx / width).clamp(0.02, 0.98)),
          onTapDown: (d) => setState(() =>
              _fraction = (d.localPosition.dx / width).clamp(0.02, 0.98)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PO (spód, całość)
              CachedNetworkImage(
                  imageUrl: widget.afterUrl, fit: BoxFit.cover),
              // PRZED (wierzch, przycięty do frakcji)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _fraction,
                  child: SizedBox(
                    width: width,
                    child: CachedNetworkImage(
                        imageUrl: widget.beforeUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              // linia + uchwyt
              Positioned(
                left: width * _fraction - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: width * _fraction - 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.compare_arrows,
                        size: 20, color: Colors.black87),
                  ),
                ),
              ),
              // etykiety
              Positioned(
                left: 8,
                top: 8,
                child: _label('PRZED'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _label('PO'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _label(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );
}

/// Otwiera dialog: para Przed/Po (suwak) albo pojedyncze zdjęcie.
void showRealizationDialog(BuildContext context, Map<String, dynamic> photo) {
  final before = photo['beforeUrl'] as String?;
  final after = photo['imageUrl'] as String? ?? '';
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: before != null && before.isNotEmpty
          ? BeforeAfterSlider(beforeUrl: before, afterUrl: after)
          : InteractiveViewer(child: CachedNetworkImage(imageUrl: after)),
    ),
  );
}

/// Miniatura realizacji: zdjęcie „Po" + plakietka gdy jest para Przed/Po.
class RealizationThumb extends StatelessWidget {
  final Map<String, dynamic> photo;
  final double size;

  const RealizationThumb({super.key, required this.photo, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final hasBefore = (photo['beforeUrl'] as String?)?.isNotEmpty == true;
    return GestureDetector(
      onTap: () => showRealizationDialog(context, photo),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: photo['imageUrl'] ?? '',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          if (hasBefore)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Przed/Po',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
