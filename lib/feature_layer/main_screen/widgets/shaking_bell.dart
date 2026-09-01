import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

import '../../../shared/constants.dart';

class ShakingBellIcon extends StatefulWidget {
  @override
  _ShakingBellIconState createState() => _ShakingBellIconState();
}

class _ShakingBellIconState extends State<ShakingBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Animacja przesunięcia w lewo i prawo
    _shakeAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Animacja lekkiego obracania dzwonka
    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0), // Ruch w poziomie
          child: Transform.rotate(
            angle: _rotateAnimation.value, // Lekkie bujanie
            origin: Offset(0, -45), // Przesunięcie osi obrotu do góry
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.notifications_active_outlined,
        size: 50,
        color: cMidPink,
      ),
    );
  }
}