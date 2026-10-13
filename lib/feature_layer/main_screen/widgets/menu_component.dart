import 'package:flutter/material.dart';
import '../widgets/bps_menu_label.dart';

class MenuComponent extends StatelessWidget {
  final bool showMenu;
  final List<MenuItem> menuItems;
  final Function(MenuItem) onMenuItemTapped;

  const MenuComponent({
    Key? key,
    required this.showMenu,
    required this.menuItems,
    required this.onMenuItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      color: isDark ? const Color(0xFF1C1B21) : Colors.white,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      height: showMenu ? menuItems.length * 48.0 + 8 : 0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: Column(
                children:
                    menuItems.map((item) => _buildMenuItem(context, item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return InkWell(
      onTap: () => onMenuItemTapped(item),
      child: MenuLabel(context, item),
    );
  }
}

class MenuItem {
  final String text;
  final int count;
  final bool isEnabled;

  //final Function(dynamic)? onTap;
  final Function()? onTap;

  MenuItem({required this.text, this.count = 0, this.onTap, this.isEnabled = true});
}
