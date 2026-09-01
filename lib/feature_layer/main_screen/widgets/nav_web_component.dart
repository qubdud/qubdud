import 'package:flutter/material.dart';

import '../../../shared/constants.dart';
import 'nav_bar_component.dart';

class NavWebComponent extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;
  final List<NavItem> navItems;

  const NavWebComponent({
    Key? key,
    required this.selectedIndex,
    required this.onNavItemTapped,
    required this.navItems,
  }) : super(key: key);

  @override
  State<NavWebComponent> createState() => _NavWebComponentState();
}

class _NavWebComponentState extends State<NavWebComponent> {
  int hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cLighterBrown,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(30),
            child: Image.asset(
              'assets/nexi_logo.png',
              scale: 2,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.navItems.length,
              itemBuilder: (context, index) {
                final item = widget.navItems[index];
                final isSelected = widget.selectedIndex == item.index;
                final isHovered = hoveredIndex == index;

                var col = item.isEnabled ? (isSelected ? cDarkBlue : (isHovered ? cDarkBlue : cDarkBrown)) : cDarkBrown.withOpacity(0.2);

                return MouseRegion(
                  onEnter: (_) => setState(() => hoveredIndex = index),
                  onExit: (_) => setState(() => hoveredIndex = -1),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        left: (isHovered || isSelected) ? 0 : -8,
                        top: 8,
                        bottom: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.isEnabled ? cDarkBlue : cDarkBrown.withOpacity(0.2),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6), // Zaokrąglenie prawego górnego rogu
                              bottomRight: Radius.circular(6), // Zaokrąglenie prawego dolnego rogu
                            ),
                          ),
                          width: 6,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.fromLTRB(20, 2, 0, 2), // Dodanie odstępów pionowych

                        leading:



                       // Image.asset(item.iconPath, width: 32, height: 32, color: col),
                        Icon(Icons.abc),


                        title: Row(
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: col,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item.count > 0)
                              CircleAvatar(
                                radius: 8,
                                foregroundColor: Colors.white,
                                backgroundColor: cMidPink,
                                child: Text(
                                  item.count.toString(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),

                        onTap: () => widget.onNavItemTapped(item.index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(padding: EdgeInsets.all(40), child: Image.asset('assets/logotypy.png')),
        ],
      ),
    );
  }
}
