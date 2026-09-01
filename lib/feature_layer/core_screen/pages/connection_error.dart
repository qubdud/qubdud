import 'dart:math';
import 'package:flutter/material.dart';

class ConnectionError extends StatefulWidget {
  const ConnectionError({super.key});

  @override
  State<ConnectionError> createState() => _ConnectionErrorState();
}

class _ConnectionErrorState extends State<ConnectionError> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late CurvedAnimation curvedAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.bounceIn, // Zmiana krzywej animacyjnej
    );
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 200),
              SelectableText(
                'PROBLEM Z POŁĄCZENIEM',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          )),
          Center(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform.rotate(angle: curvedAnimation.value * 2 * pi, child: SizedBox.shrink());
              },
            ),
          ),
        ],
      ),
    );
  }
}
