import 'package:flutter/material.dart';

import 'controller.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final PrayerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = const int.fromEnvironment('INITIAL_TAB');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: IndexedStack(index: _index, children: [
          PrayerScreen(controller: widget.controller),
          QiblaScreen(active: _index == 1),
        ]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1020),
          border: Border(
              top: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.25), width: 0.8)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.gold.withValues(alpha: 0.16),
            labelTextStyle: WidgetStateProperty.resolveWith((s) => body(12,
                color: s.contains(WidgetState.selected)
                    ? AppColors.gold
                    : AppColors.textDim,
                weight: FontWeight.w600)),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                color: s.contains(WidgetState.selected)
                    ? AppColors.gold
                    : AppColors.textDim)),
          ),
          child: NavigationBar(
            elevation: 0,
            height: 64,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.access_time_rounded), label: 'Vakitler'),
              NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Kıble'),
            ],
          ),
        ),
      ),
    );
  }
}
