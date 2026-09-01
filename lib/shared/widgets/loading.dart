import 'package:flutter/material.dart';

import '../constants.dart';

class Loading extends StatefulWidget {
  final bool? noText;
  final double? scale;

  const Loading({super.key, this.noText, this.scale});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Total animation duration
    )..repeat(); // Repeat the animation indefinitely

    // Opacity animation: fade in and fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    // Position animation: move from left to right
    _positionAnimation = Tween<double>(begin: 149, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 300,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_positionAnimation.value - 72, 0), // Płynne przesuwanie
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Icon(Icons.downloading_outlined),
                  ),
                );
              },
            ),
          ),
        ),
        if (false) //if (!(widget.noText ?? false))
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Loading...",
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: cDarkBrown,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
