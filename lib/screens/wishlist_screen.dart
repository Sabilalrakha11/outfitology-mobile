import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import 'product_detail_screen.dart';

// ============================================================
// WISHLIST MANAGER — Singleton untuk manage state wishlist
// ============================================================
class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  bool isWishlisted(dynamic productId) =>
      _items.any((p) => p['id'].toString() == productId.toString());

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wishlist');
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw);
      _items.clear();
      _items.addAll(decoded.cast<Map<String, dynamic>>());
      notifyListeners();
    }
  }

  Future<void> toggle(Map<String, dynamic> product) async {
    final id = product['id'].toString();
    if (isWishlisted(id)) {
      _items.removeWhere((p) => p['id'].toString() == id);
    } else {
      _items.add(Map<String, dynamic>.from(product));
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(_items));
  }
}

// ============================================================
// WISHLIST SCREEN
// ============================================================
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _manager = WishlistManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_refresh);
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = _manager.items;
    return Scaffold(
      backgroundColor: AppTheme.fog,
      appBar: AppBar(
        backgroundColor: AppTheme.fog,
        title: const Text('WISHLIST'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Clear Wishlist', style: AppTheme.headingBold),
                    content: Text('Remove all ${items.length} items?', style: AppTheme.bodyMedium),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: Text('CANCEL', style: AppTheme.labelCaps)),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: Text('CLEAR', style: AppTheme.labelCaps.copyWith(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final item in List.from(items)) {
                    await _manager.toggle(item);
                  }
                }
              },
              child: Text('CLEAR', style: AppTheme.labelCaps),
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_outline_rounded,
              title: 'YOUR WISHLIST IS EMPTY',
              subtitle: 'Save items you love by tapping the heart icon.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _WishlistCard(product: items[i], manager: _manager),
            ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final WishlistManager manager;
  const _WishlistCard({required this.product, required this.manager});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(children: [
              Container(
                width: double.infinity, color: AppTheme.fog,
                child: Image.network(
                  product['gambar_url'] ?? '',
                  fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: AppTheme.mist)),
                ),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => manager.toggle(product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded, size: 18, color: Colors.red),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(product['nama'] ?? '', style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('IDR ${product['harga'] ?? 0}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.ink)),
        ],
      ),
    );
  }
}

// ============================================================
// WISHLIST HEART BUTTON — Reusable widget untuk product card
// ============================================================
class WishlistHeartButton extends StatefulWidget {
  final Map<String, dynamic> product;
  final Color? color;
  const WishlistHeartButton({super.key, required this.product, this.color});

  @override
  State<WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends State<WishlistHeartButton>
    with SingleTickerProviderStateMixin {
  final _manager = WishlistManager();
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _manager.addListener(_rebuild);
  }

  @override
  void dispose() {
    _manager.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isLiked = _manager.isWishlisted(widget.product['id']);
    return GestureDetector(
      onTap: () async {
        await _manager.toggle(widget.product);
        _controller.forward(from: 0);
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            key: ValueKey(isLiked),
            size: 22,
            color: isLiked ? Colors.red.shade400 : (widget.color ?? Colors.white),
            shadows: const [Shadow(blurRadius: 8, color: Colors.black26)],
          ),
        ),
      ),
    );
  }
}