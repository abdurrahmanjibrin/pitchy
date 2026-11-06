import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../history/practice_history_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PracticeHistoryScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withOpacity(0.25),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.secondary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded, color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.history_rounded, color: AppColors.secondary),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded, color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.insights_rounded, color: AppColors.secondary),
              label: 'Progres',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded,
                  color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.secondary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

