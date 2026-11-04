import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers & Screens
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/home/screens/home_screen.dart';
import '../../wild_lens/screens/camera_screen.dart';
import '../../eco_market/screens/market_screen.dart';
import '../../survival_kit/screens/survival_home_screen.dart';
import '../../sos_alert/screens/sos_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WildLensScreen(),
    const MarketScreen(),
    const SurvivalHomeScreen(),
    const SosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isAppInitialized = ref.watch(appInitProvider);

    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && theme.brightness == Brightness.dark);

    final navBgColor = isDark ? const Color(0xFF0E1914).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);
    final activeColor = const Color(0xFF9BE15D);
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF07110D) : const Color(0xFFF4F8F5),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: isAppInitialized
          ? Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 25, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: navBgColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home', activeColor, inactiveColor),
                  _buildNavItem(1, Icons.camera_alt_rounded, 'Lens', activeColor, inactiveColor),
                  _buildNavItem(2, Icons.storefront_rounded, 'Market', activeColor, inactiveColor),
                  _buildNavItem(3, Icons.menu_book_rounded, 'Guide', activeColor, inactiveColor),
                  _buildNavItem(4, Icons.emergency_rounded, 'SOS', const Color(0xFFFF5252), inactiveColor),
                ],
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor, Color inactiveColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSelected ? 24 : 22, color: isSelected ? activeColor : inactiveColor),
            if (isSelected) ...[const SizedBox(height: 2), Text(label, style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold))]
          ],
        ),
      ),
    );
  }
}