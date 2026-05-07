import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home_screen.dart';
import 'ride_history_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bounceController;

  final List<Widget> _screens = const [
    HomeScreen(),
    RideHistoryScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.history_outlined,
        activeIcon: Icons.history_rounded,
        label: 'My Rides'),
    _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _bounceController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _onTap,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _AnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: Tween(begin: 0.7, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: anim, curve: Curves.easeOutBack),
                            ),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: selected
                              ? Container(
                                  key: ValueKey('active_$i'),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: IniatoTheme.greenSurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item.activeIcon,
                                      color: IniatoTheme.green, size: 22),
                                )
                              : Padding(
                                  key: ValueKey('inactive_$i'),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(item.icon,
                                      color: IniatoTheme.textHint, size: 22),
                                ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? IniatoTheme.green : IniatoTheme.textHint,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
