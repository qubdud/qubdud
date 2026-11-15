import 'package:flutter/material.dart';
import '../constants.dart';

enum ButtonColorType { green, orange, white, transparent }

class WButton extends StatelessWidget {
  final String text;
  final ButtonColorType colorType;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final int count;

  const WButton({
    super.key,
    required this.text,
    this.colorType = ButtonColorType.green,
    this.isEnabled = true,
    this.onPressed,
    this.count = 0,
  });

  static final Map<ButtonColorType, Color> backgroundColors = {
    ButtonColorType.green: cDarkBlue,
    ButtonColorType.orange: cMidOrange,
    ButtonColorType.white: Colors.white,
    ButtonColorType.transparent: Colors.transparent, // Nowy kolor
  };

  static final Map<ButtonColorType, Color> foregroundColors = {
    ButtonColorType.green: Colors.white,
    ButtonColorType.orange: cDarkBlue,
    ButtonColorType.white: cDarkBlue,
    ButtonColorType.transparent: cDarkBlue,
  };

  static final Map<ButtonColorType, Color> pressedColors = {
    ButtonColorType.green: cDarkerBlue,
    ButtonColorType.orange: cMidOrange,
    ButtonColorType.white: Colors.white,
    ButtonColorType.transparent: cDarkBlue.withOpacity(0.5), // Kolor po naciśnięciu
  };

  static final Map<ButtonColorType, Color> borderColors = {
    ButtonColorType.green: Colors.transparent,
    ButtonColorType.orange: Colors.transparent,
    ButtonColorType.white: cDarkBlue,
    ButtonColorType.transparent: cDarkBlue,
  };

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isEnabled
        ? backgroundColors[colorType] ?? Colors.grey
        : Colors.grey;

    final Color foregroundColor = isEnabled
        ? foregroundColors[colorType] ?? Colors.white
        : Colors.white;

    final Color borderColor = borderColors[colorType] ?? Colors.transparent;

    final Color pressedBackgroundColor = isEnabled
        ? pressedColors[colorType] ?? backgroundColor
        : backgroundColor;

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor,
        disabledForegroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(
            color: borderColor,
            width: colorType == ButtonColorType.white ? 1.5 : 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, kButtonHeight),
        shadowColor: Colors.transparent,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.pressed) ? pressedBackgroundColor : null,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 15,
            ),
          ),
          if (count > 0)   const SizedBox(width: 8),
          if (count > 0)
            CircleAvatar(
              radius: 10,
              foregroundColor: Colors.white,
              backgroundColor: cMidPink,
              child: Text(
                textAlign: TextAlign.center,
                count.toString(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
