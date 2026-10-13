import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class WAnimatedDropdown extends StatefulWidget {
  final TextEditingController controller;
  final List<String> items;
  final String? label;
  final String hintText;
  final Function(String)? onItemSelected;
  final Function(bool)? onDropdownVisibleChanged; // 🔥 Nowy callback
  final String? errorText;
  final bool isSearchable;
  final isEnabled;

  const WAnimatedDropdown({
    Key? key,
    required this.controller,
    required this.label,
    required this.items,
    required this.hintText,
    this.onItemSelected,
    this.onDropdownVisibleChanged, // 🔥 Nowy callback
    this.errorText,
    this.isSearchable = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<WAnimatedDropdown> createState() => _WAnimatedDropdownState();
}

class _WAnimatedDropdownState extends State<WAnimatedDropdown> {
  // zawsze aktualny kontroler rodzica (rodzic może go podmienić)
  TextEditingController get _controller => widget.controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool isDropdownVisible = false;
  late List<String> filteredItems;

  @override
  void initState() {
    super.initState();

    filteredItems = widget.items;
    _focusNode.addListener(() {
      if (mounted && widget.isEnabled) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });

        if (!_focusNode.hasFocus) {
          if (!widget.items.contains(_controller.text)) {
            setState(() {
              _controller.clear();
              if (widget.onItemSelected != null) {
                widget.onItemSelected!('');
              }
            });
          }
          setState(() {
            isDropdownVisible = false;
            widget.onDropdownVisibleChanged?.call(isDropdownVisible);
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant WAnimatedDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // np. nowa lista branż po zmianie kategorii
    if (!listEquals(oldWidget.items, widget.items)) filteredItems = widget.items;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var borderColor = widget.isEnabled
        ? (widget.errorText != null
            ? cMidPink // Różowy na błąd
            : _isFocused
                ? cDarkBrown // Zielony na fokus
                : const Color(0x00888888))
        : cDisabledBorderColor; // Jasny zielony na domyślny

    final errorTextColor = cMidPink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 4),
        // Pole wejściowe

        Container(
          decoration: BoxDecoration(
            color: widget.isEnabled ? Colors.white : cDisabledBorderColor,
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
          child: GestureDetector(
            onTap: widget.isEnabled
                ? () {
                    setState(() {
                      if (_focusNode.hasFocus) {
                        _focusNode.unfocus();
                      } else {
                        _focusNode.requestFocus();
                      }

                      isDropdownVisible = !isDropdownVisible;
                      widget.onDropdownVisibleChanged?.call(isDropdownVisible);


                      // Reset wartości, jeśli nie znajduje się na liście
                      if (!widget.items.contains(_controller.text)) {
                        _controller.clear();
                        if (widget.onItemSelected != null) {
                          widget.onItemSelected!('');
                        }
                      }

                      // Reset filtracji
                      filteredItems = widget.items;
                    });
                  }
                : null,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    focusNode: widget.isEnabled ? _focusNode : null,
                    readOnly: !isDropdownVisible || !widget.isSearchable || !widget.isEnabled,
                    decoration: InputDecoration(
                      prefixIcon: isDropdownVisible
                          ? (widget.isSearchable
                              ? Icon(
                                  Icons.search,
                                  color: cDarkBrown,
                                )
                              : null)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: InputBorder.none,
                      hintText: isDropdownVisible ? (!widget.isSearchable ? widget.hintText : null) : widget.hintText,
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: widget.isEnabled ? (_isFocused ? cDarkBrown : cDarkBrown.withOpacity(0.7)) : cDisabledColor,
                      ),
                    ),
                    onTap: widget.isEnabled
                        ? () {
                            setState(() {
                              if (!widget.items.contains(_controller.text)) {
                                _controller.clear();
                                if (widget.onItemSelected != null) {
                                  widget.onItemSelected!('');
                                }
                              }

                              if (_focusNode.hasFocus) {
                                _focusNode.unfocus();
                              } else {
                                _focusNode.requestFocus();
                              }

                              isDropdownVisible = !isDropdownVisible;
                              widget.onDropdownVisibleChanged?.call(isDropdownVisible);
                              // Reset the filtered items
                              filteredItems = widget.items;
                            });
                          }
                        : null,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {
                          filteredItems = widget.items.where((element) => element.toLowerCase().contains(value.toLowerCase())).toList();
                        });
                      }
                    },
                  ),
                ),
                Icon(
                  isDropdownVisible ? Icons.expand_less_outlined : Icons.expand_more_outlined,
                  color: widget.isEnabled ? (_isFocused ? cDarkBrown : cDarkBrown.withOpacity(0.7)) : cDisabledColor,
                ),
                SizedBox(
                  width: 8,
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),
        // Tekst błędu
        if (widget.errorText != null)
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 14,
              color: errorTextColor,
            ),
          ),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isDropdownVisible ? (filteredItems.length > 5 ? 200 : (filteredItems.length > 0 ? filteredItems.length * 40.0 : 50)) : 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ]),
              child: filteredItems.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = item == _controller.text;
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected ? cDarkBrown.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(index == 0 ? 8 : 0),
                              topRight: Radius.circular(index == 0 ? 8 : 0),
                              bottomLeft: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                              bottomRight: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(index == 0 ? 8 : 0),
                                topRight: Radius.circular(index == 0 ? 8 : 0),
                                bottomLeft: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                                bottomRight: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                              ),
                              onTap: () {
                                setState(() {
                                  _controller.text = item;
                                  _focusNode.unfocus();
                                  isDropdownVisible = false;
                                  widget.onDropdownVisibleChanged?.call(isDropdownVisible);
                                });
                                if (widget.onItemSelected != null) {
                                  widget.onItemSelected!(item);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(index == 0 ? 8 : 0),
                                  topRight: Radius.circular(index == 0 ? 8 : 0),
                                  bottomLeft: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                                  bottomRight: Radius.circular(index == filteredItems.length - 1 ? 8 : 0),
                                ),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    item,
                                    style: TextStyle(color: cDarkBrown, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Brak wyników',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
