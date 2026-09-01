import 'package:flutter/material.dart';

import '../constants.dart';

class WCheckbox extends StatelessWidget {
  final bool value;
  final bool isError;
  final bool isEnabled;
  final ValueChanged<bool?> onChanged;

  const WCheckbox({
    Key? key,
    this.isError = false,
    this.isEnabled = true,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? () => onChanged(!value) : null,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: isEnabled ? (value ? cDarkBrown : Colors.white) : cDisabledColor, // Tło w trybie disabled
              border: Border.all(
                color: isEnabled
                    ? (isError
                        ? cMidPink // Kolor ramki w trybie błędu
                        : (value ? cDarkBrown : Colors.white))
                    : cDisabledBorderColor, // Ramka w trybie disabled
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ]),
          child: value
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 1, 1),
                  child: Image.asset(
                    'assets/icons/v.png',
                    color: isEnabled ? Colors.white : cDisabledBorderColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
