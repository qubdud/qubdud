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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) => _buildNavItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final isSelected = selectedIndex == item.index;
    final colorStart = item.isEnabled ? (!isSelected ? cDarkBrown.withOpacity(0.6) : cDarkBlue) : (!isSelected ? cDarkBrown.withOpacity(0.6) : cDarkBlue).withOpacity(0.2);
    final colorEnd = item.isEnabled ? (isSelected ? cDarkBlue : cDarkBrown.withOpacity(0.6)) : (isSelected ? cDarkBlue : cDarkBrown.withOpacity(0.6)).withOpacity(0.2);

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
                    //Image.asset(
                    //  (item.isMenu & isSelected) ? 'assets/icons/x.png' : item.iconPath,
                    //  scale: 2,
                    //  color: color,
                    //),
                    Icon((item.isMenu & isSelected) ? Icons.close : item.iconPath,color: color,),
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

  bool get isMenu => index == 10;

  NavItem({
    this.count = 0,
    this.isEnabled = true,
    required this.index,
    required this.label,
    required this.iconPath,
    this.onTap,
  });
}
