import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common_bottom_nav.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'timer_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TimerScreen(),
    RecordScreen(),
    Center(child: Text('설정', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final navItems = [
      NavItem(icon: Icons.home, label: l10n.home),
      NavItem(icon: Icons.timer, label: l10n.timer),
      NavItem(icon: Icons.edit_note, label: l10n.record),
      NavItem(icon: Icons.settings, label: l10n.settings),
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _currentIndex,
        items: navItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
