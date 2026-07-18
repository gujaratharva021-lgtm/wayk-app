import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';

import '../theme/app_theme.dart';
import 'alarms_screen.dart';
import 'dashboard_screen.dart';
import 'health_screen.dart';
import 'more_screen.dart';

/// The main app shell after login: a custom floating pill nav bar with
/// 4 tabs -- Dashboard, Alarms, Health, and More (diet/exercise/grocery/
/// calculators/profile).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeMaxWidth.value = 960;
      });
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      homeMaxWidth.value = 480;
    }
    super.dispose();
  }

  final _tabs = const [
    DashboardScreen(),
    AlarmsScreen(),
    HealthScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(bottom: false, child: _tabs[_currentIndex]),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded, 'Home'),
    (Icons.alarm_rounded, 'Alarms'),
    (Icons.favorite_rounded, 'Health'),
    (Icons.more_horiz_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = i == currentIndex;
            final item = _items[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.sunrise.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, color: selected ? AppColors.sunrise : AppColors.textMuted, size: 22),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? AppColors.sunrise : AppColors.textMuted,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
