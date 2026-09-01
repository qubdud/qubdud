import 'package:flutter/material.dart';

import '../constants.dart';

enum GradientType {
  orange, // Pierwszy zestaw (domyślny)
  grey, // Nowy zestaw przykład
  green, // Kolejny przykład
}

class WCard extends StatelessWidget {
  final Widget child;
  final GradientType? gradientType; // Enum dla zestawów gradientów
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;

  const WCard({
    Key? key,
    required this.child,
    this.gradientType,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,// Opcjonalny typ gradientu
  }) : super(key: key);

  LinearGradient? _getGradient() {
    if (gradientType == null) return null;

    switch (gradientType) {
      case GradientType.orange:
        return const LinearGradient(
          colors: [cGradientOrangeStart, cGradientOrangeEnd],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case GradientType.green:
        return const LinearGradient(
          colors: [Color(0xFF066A4D), Color(0xFF033422)], // Przykład gradientu
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );




      case GradientType.grey:
        return const LinearGradient(
          colors: [Color(0xFFdddddd), Color(0xFFeeeeee)], // Przykład gradientu
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: margin ?? EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: padding ?? EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
        decoration: BoxDecoration(
          color: gradientType != null
              ? null
              : (color ?? (isDark ? const Color(0xFF232228) : Colors.white)),
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(16.0),
          border: borderColor != null ? Border.all(color: borderColor!, width: 2.0) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Cień
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
