import 'package:flutter/material.dart';

import '../../../shared/constants.dart';

class NavBarComponent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;
  final List<NavItem> navItems;

  const NavBarComponent({
    Key? key,
    required this.selectedIndex,
    required this.onNavItemTapped,
    required this.navItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1C1B21) : Colors.white,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) => _buildNavItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final isSelected = selectedIndex == item.index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive =
        isDark ? Colors.white.withOpacity(0.6) : cDarkBrown.withOpacity(0.6);
    final colorStart = item.isEnabled ? (!isSelected ? inactive : cDarkBlue) : (!isSelected ? inactive : cDarkBlue).withOpacity(0.2);
    final colorEnd = item.isEnabled ? (isSelected ? cDarkBlue : inactive) : (isSelected ? cDarkBlue : inactive).withOpacity(0.2);

    return InkWell(
      onTap: () {
        onNavItemTapped(item.index);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCirc,
            width: MediaQuery.of(context).size.width / navItems.length,
            height: 90,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: colorStart,
                end: colorEnd,
              ),
              duration: const Duration(milliseconds: 200),
              builder: (context, color, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon((item.isMenu & isSelected) ? Icons.close : item.iconPath, color: color),
                        if (item.count > 0 && !item.locked)
                          Positioned(
                            right: -12,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.count > 99 ? '99+' : '${item.count}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (item.locked)
                          Positioned(
                            right: -9,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1B21) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.lock, size: 12, color: color),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem {
  final int index;
  final int count;
  final String label;
  final IconData iconPath;
  final bool isEnabled;
  final Function()? onTap;

  /// Dostępne dopiero po zalogowaniu — pokazuje kłódkę (tryb anonimowy).
  final bool locked;

  bool get isMenu => index == 10;

  NavItem({
    this.count = 0,
    this.isEnabled = true,
    this.locked = false,
    required this.index,
    required this.label,
    required this.iconPath,
    this.onTap,
  });
}
