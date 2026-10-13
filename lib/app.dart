import 'package:flutter/material.dart';
import 'features/calculations/presentation/calculations_list_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/sync/presentation/sync_screen.dart';

class MainShellApp extends StatefulWidget {
  const MainShellApp({super.key});

  @override
  State<MainShellApp> createState() => _MainShellAppState();
}

class _MainShellAppState extends State<MainShellApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onTabChange: (i) => setState(() => _currentIndex = i)),
      const CalculationsListScreen(),
      const HistoryScreen(),
      const SyncScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Hesaplar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Kayıtlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined),
            selectedIcon: Icon(Icons.cloud_sync_rounded),
            label: 'Servis',
          ),
        ],
      ),
    );
  }
}

