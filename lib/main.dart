import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/search_screen.dart';

// ============================================================
// OUTFITOLOGY — Main entry point (updated v2)
// ============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Load wishlist & notifications on startup
  WishlistManager().loadFromPrefs();
  NotificationManager().load();
  runApp(const OutfitologyApp());
}

// ============================================================
// APP THEME — Design system terpusat
// ============================================================
class AppTheme {
  // Colors
  static const Color ink = Color(0xFF0D0D0D);
  static const Color navy = Color(0xFF0A192F);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color fog = Color(0xFFF5F5F3);
  static const Color mist = Color(0xFFEAEAE8);
  static const Color stone = Color(0xFF9E9E99);

  // Text Styles
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 36, fontWeight: FontWeight.w700, color: ink, height: 1.1, letterSpacing: -0.5);
  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 24, fontWeight: FontWeight.w700, color: ink, height: 1.2);
  static TextStyle get headingBold => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w700, color: ink, letterSpacing: 1.5);
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.6);
  static TextStyle get bodySmall => GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400, color: stone, height: 1.5);
  static TextStyle get priceLarge => GoogleFonts.dmSans(
    fontSize: 20, fontWeight: FontWeight.w600, color: ink);
  static TextStyle get priceSmall => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w600, color: navy);
  static TextStyle get labelCaps => GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600, color: stone, letterSpacing: 2.0);
  static TextStyle get buttonText => GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w700, color: canvas, letterSpacing: 1.5);

  // Spacing (8pt grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: canvas,
    primaryColor: navy,
    colorScheme: const ColorScheme.light(primary: navy, surface: canvas),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas, elevation: 0, scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: ink), centerTitle: true,
      titleTextStyle: GoogleFonts.dmSans(
        color: ink, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 2.5),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    dividerColor: mist,
    dividerTheme: const DividerThemeData(color: mist, thickness: 1, space: 0),
    textTheme: GoogleFonts.dmSansTextTheme(),
    splashColor: Colors.transparent,
    highlightColor: fog,
  );
}

class OutfitologyApp extends StatelessWidget {
  const OutfitologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfitology',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// MAIN NAVIGATOR — 5-tab navigation
// ============================================================
class MainNavigator extends StatefulWidget {
  final int initialIndex;
  const MainNavigator({super.key, this.initialIndex = 0});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  late int _selectedIndex;

  @override
  void initState() { super.initState(); _selectedIndex = widget.initialIndex; }

  static final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const CartScreen(),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV — 5 tabs
// ============================================================
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        border: Border(top: BorderSide(color: AppTheme.mist, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'HOME', index: 0, selected: selectedIndex, onTap: onTap),
              _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'CATEGORY', index: 1, selected: selectedIndex, onTap: onTap),
              _CartNavItem(selected: selectedIndex, onTap: onTap),
              _WishlistNavItem(selected: selectedIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'ACCOUNT', index: 4, selected: selectedIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, selected;
  final ValueChanged<int> onTap;

  const _NavItem({required this.icon, required this.activeIcon,
    required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(isSelected ? activeIcon : icon,
              key: ValueKey(isSelected), size: 22,
              color: isSelected ? AppTheme.ink : AppTheme.stone),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTheme.labelCaps.copyWith(
              color: isSelected ? AppTheme.ink : AppTheme.stone, fontSize: 9, letterSpacing: 1),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// Cart icon with badge
class _CartNavItem extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _CartNavItem({required this.selected, required this.onTap});

  @override
  State<_CartNavItem> createState() => _CartNavItemState();
}

class _CartNavItemState extends State<_CartNavItem> {
  // Expose cart count via global notifier — bisa integrate dgn CartManager
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected == 2;
    return GestureDetector(
      onTap: () => widget.onTap(2),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(isSelected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
              size: 22, color: isSelected ? AppTheme.ink : AppTheme.stone),
            if (_cartCount > 0)
              Positioned(top: -5, right: -5,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(color: AppTheme.ink, shape: BoxShape.circle),
                  child: Center(child: Text(
                    _cartCount > 9 ? '9+' : '$_cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                  )),
                )),
          ]),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTheme.labelCaps.copyWith(
              color: isSelected ? AppTheme.ink : AppTheme.stone, fontSize: 9, letterSpacing: 1),
            child: const Text('BAG'),
          ),
        ]),
      ),
    );
  }
}

// Wishlist icon with count badge
class _WishlistNavItem extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _WishlistNavItem({required this.selected, required this.onTap});

  @override
  State<_WishlistNavItem> createState() => _WishlistNavItemState();
}

class _WishlistNavItemState extends State<_WishlistNavItem> {
  final _manager = WishlistManager();

  @override
  void initState() { super.initState(); _manager.addListener(_rebuild); }
  @override
  void dispose() { _manager.removeListener(_rebuild); super.dispose(); }
  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected == 3;
    final count = _manager.items.length;
    return GestureDetector(
      onTap: () => widget.onTap(3),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(isSelected ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: 22, color: isSelected ? Colors.red.shade400 : AppTheme.stone),
            if (count > 0)
              Positioned(top: -5, right: -5,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
                  child: Center(child: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                )),
          ]),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTheme.labelCaps.copyWith(
              color: isSelected ? AppTheme.ink : AppTheme.stone, fontSize: 9, letterSpacing: 1),
            child: const Text('SAVED'),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS — Reusable
// ============================================================

/// Tombol hitam full-width ala Uniqlo
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const PrimaryButton({super.key, required this.label, required this.onPressed,
    this.isLoading = false, this.height = 52});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(color: widget.onPressed == null ? AppTheme.stone : AppTheme.ink),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.label, style: AppTheme.buttonText),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerBox extends StatefulWidget {
  final double width, height;
  final double borderRadius;
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 2});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0), end: Alignment(_anim.value, 0),
            colors: const [Color(0xFFEEEEEC), Color(0xFFF8F8F6), Color(0xFFEEEEEC)],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title,
    required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppTheme.mist),
          const SizedBox(height: AppTheme.md),
          Text(title, style: AppTheme.headingBold, textAlign: TextAlign.center),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sm),
            Text(subtitle, style: AppTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppTheme.lg),
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: AppTheme.headingBold.copyWith(
                decoration: TextDecoration.underline)),
            ),
          ],
        ]),
      ),
    );
  }
}