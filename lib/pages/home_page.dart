import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import 'package:urban_route/pages/navigate.dart';
import 'package:urban_route/pages/profile_settings_page.dart';
import 'package:urban_route/pages/report_page.dart';
import 'package:urban_route/pages/map_page.dart';
import 'package:urban_route/components/bottom_nav_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // Pages in the same order as the navigation items
  final List<Widget> _pages = [
    const HomeContent(),
    const ReportPage(),
    const ProfileSettingsPage(),
    const MapPage(),
    const NavigatePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 0;
    }
      
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepBlue,
            AppColors.brightCyan.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'home.home_page'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'home.welcome_back'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
