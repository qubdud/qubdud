import 'package:flutter/material.dart';
import '../constants.dart';

class WInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? errorText;
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Icon? prefixIcon;
  final Color? focusColor;
  final int maxLines;
  final bool isPassword;
  final bool isSend;
  final bool readOnly;
  final bool obscureText;
  final bool blockCopy;
  final Function()? onTogglePasswordVisibility;
  final Function()? onSend;
  final Function()? onEditingComplete;


  const WInputField({
    Key? key,
    this.controller,
    this.label,
    this.initialValue,
    this.errorText,
    this.hintText,
    this.blockCopy = false,
    this.isPassword = false,
    this.isSend = false,
    this.obscureText = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTogglePasswordVisibility,
    this.onSend,
    this.onEditingComplete,
    this.prefixIcon,
    this.focusColor,
    this.onChanged,
  }) : super(key: key);

  @override
  _WInputFieldState createState() => _WInputFieldState();
}

class _WInputFieldState extends State<WInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? cMidPink // Różowy na błąd
        : _isFocused
            ? (widget.focusColor ?? cDarkBrown)
            : const Color(0x00888888); // Jasny zielony na domyślny

    final helpTextColor = widget.errorText != null ? const Color(0xFFFB5C85) : const Color(0xFF054E3E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Górny pasek z etykietą
        if (widget.label != null)
          Text(
            widget.label!.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 4),
        // Pole wejściowe
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(


                  enableInteractiveSelection: !widget.blockCopy, // blokuje zaznaczanie i kopiowanie
                  contextMenuBuilder: widget.blockCopy?(context, editableTextState) {
                    return Container(); // usuwa menu z "paste"
                  }:null,



                  initialValue: widget.initialValue,
                  readOnly: widget.readOnly,
                  maxLines: widget.maxLines,
                  controller: widget.controller,
                  obscureText: widget.isPassword && widget.obscureText,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    prefixIcon: widget.prefixIcon,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: InputBorder.none,
                    hintText: widget.hintText ?? 'Wpisz...',
                    hintStyle: TextStyle(
                      fontFamily: 'FiraSans',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: _isFocused ? cDarkBrown : cDarkBrown.withOpacity(0.7),
                    ),
                  ),
                  onChanged: widget.onChanged,
                  onEditingComplete: widget.onEditingComplete,
                ),
              ),
              if (widget.isPassword)
                IconButton(
                  icon: Icon(
                    widget.obscureText ? Icons.visibility_off : Icons.visibility,
                    color: cDarkBrown,
                  ),
                  onPressed: widget.onTogglePasswordVisibility,
                ),
              if (widget.isSend)
                IconButton(
                  icon: Icon(
                    size: 24,
                    Icons.send_outlined,
                    color: cDarkerBlue,
                  ),
                  onPressed: widget.onSend,
                ),
            ],
          ),
        ),
        if (widget.errorText != null) const SizedBox(height: 4),
        if (widget.errorText != null)
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 14,
              color: helpTextColor,
            ),
          ),
      ],
    );
  }
}
