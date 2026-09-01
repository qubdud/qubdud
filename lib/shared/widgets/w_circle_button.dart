import 'package:flutter/material.dart';

import '../constants.dart';

enum CircleButtonColorType { brown, orange }

class WCircularIconButton extends StatelessWidget {
  final CircleButtonColorType colorType;
  final bool isEnabled;
  final VoidCallback? onTap;
  final bool isNext; // Nowy parametr do wyboru strzałki (next/back)

  const WCircularIconButton({
    this.colorType = CircleButtonColorType.brown,
    this.isEnabled = true,
    this.onTap,
    this.isNext = true, // Domyślnie strzałka w prawo (next)
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Ustaw kolory na podstawie `colorType` i `isEnabled`
    final Color backgroundColor = isEnabled ? (colorType == CircleButtonColorType.brown ? cMidBrown.withOpacity(0.3) : cMidOrange) : Colors.grey;

    final Color splashColor = isEnabled ? (colorType == CircleButtonColorType.brown ? cMidBrown.withOpacity(0.5) : cMidOrange) : backgroundColor;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          splashColor: splashColor,
          onTap: isEnabled ? onTap : null,
          child: Transform.rotate(
            angle: isNext ? 0 : 3.14159, // Obrócenie o 180 stopni, jeśli isNext == false
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Image.asset(
                'assets/icons/next.png', // Tutaj można użyć tej samej ikony dla obu kierunków
                width: 20,
                height: 20,
                color: cDarkBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
