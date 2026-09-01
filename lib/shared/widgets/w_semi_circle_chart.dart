import 'dart:math';

import 'package:flutter/cupertino.dart';

class WSemiCircleChart extends StatelessWidget {
  final List<int> values;
  final List<Color> colors;
  final double spacing;
  final double rectWidth;
  final double rectHeight;
  final double cornerRadius;
  final double stepAngle;

  const WSemiCircleChart({
    Key? key,
    required this.values,
    required this.colors,
    this.spacing = 0.15,
    this.rectWidth = 15.0,
    this.rectHeight = 30.0,
    this.cornerRadius = 7.0,
    this.stepAngle = 0.01, // Kąt przesunięcia prostokątów
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 150), // Rozmiar półokręgu
      painter: SemiCirclePainter(
        values: values,
        colors: colors,
        spacing: spacing,
        rectWidth: rectWidth,
        rectHeight: rectHeight,
        cornerRadius: cornerRadius,
        stepAngle: stepAngle,
      ),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  final double spacing;
  final double rectWidth;
  final double rectHeight;
  final double cornerRadius;
  final double stepAngle;

  SemiCirclePainter({
    required this.values,
    required this.colors,
    required this.spacing,
    required this.rectWidth,
    required this.rectHeight,
    required this.cornerRadius,
    required this.stepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height;
    final double radius = size.width / 2 - rectHeight / 2;
    final Offset center = Offset(centerX, centerY);

    // Filtrowanie zerowych wartości, aby ich nie uwzględniać w podziale
    List<int> nonZeroValues = values.where((v) => v > 0).toList();
    if (nonZeroValues.isEmpty) return; // Jeśli wszystkie wartości to 0, nie rysujemy nic

    int totalValue = nonZeroValues.fold(0, (sum, item) => sum + item);

    double totalSweep = pi; // Pełny półokrąg (180 stopni)
    double totalSpacing = spacing * (nonZeroValues.length - 1);
    double availableAngle = totalSweep - totalSpacing; // Kąt dostępny dla rzeczywistych wartości

    double startAngle = pi;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue; // Pomijamy zerowe wartości przy rysowaniu

      // Obliczamy proporcjonalny kąt dla wartości > 0
      double sweepAngle = (values[i] / totalValue) * availableAngle;

      paint.color = colors[i % colors.length];

      for (double angle = 0; angle < sweepAngle; angle += stepAngle) {
        double midAngle = startAngle + angle;
        double rectCenterX = center.dx + radius * cos(midAngle);
        double rectCenterY = center.dy + radius * sin(midAngle);

        Rect rect = Rect.fromCenter(
          center: Offset(rectCenterX, rectCenterY),
          width: rectWidth,
          height: rectHeight,
        );

        RRect roundedRect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

        canvas.save();
        canvas.translate(rectCenterX, rectCenterY);
        canvas.rotate(midAngle - pi / 2);
        canvas.translate(-rectCenterX, -rectCenterY);
        canvas.drawRRect(roundedRect, paint);
        canvas.restore();
      }

      startAngle += sweepAngle + spacing;
    }
  }

  @override
  bool shouldRepaint(SemiCirclePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.spacing != spacing ||
      oldDelegate.rectWidth != rectWidth ||
      oldDelegate.rectHeight != rectHeight ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.stepAngle != stepAngle;
}
