import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import 'package:easy_localization/easy_localization.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 10,
      selectedItemColor:  AppColors.deepBlue,
      unselectedItemColor: Colors.grey.shade500,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      iconSize: 26,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'components.nav_bar.home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_outlined),
          activeIcon: Icon(Icons.report),
          label: 'components.nav_bar.report'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'components.nav_bar.map'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.navigate_next_outlined),
          activeIcon: Icon(Icons.navigate_next),
          label: 'components.nav_bar.navigate'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'components.nav_bar.profile'.tr(),
        ),
      ],
    );
  }
}
