import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:outfitology/screens/wishlist_screen.dart';
import 'dart:convert';
import '../main.dart';
import 'product_detail_screen.dart';

// ============================================================
// CATEGORY SCREEN — Browse by kategori dengan filter & sort
// ============================================================
class CategoryScreen extends StatefulWidget {
  final String? initialCategory;
  const CategoryScreen({super.key, this.initialCategory});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with TickerProviderStateMixin {
  // Kategori outfit — sesuaikan dengan data Laravel lu
  static const List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.grid_view_rounded},
    {'id': 'pria', 'label': 'Men', 'icon': Icons.man_rounded},
    {'id': 'wanita', 'label': 'Women', 'icon': Icons.woman_rounded},
    {'id': 'kaos', 'label': 'T-Shirts', 'icon': Icons.checkroom_rounded},
    {'id': 'kemeja', 'label': 'Shirts', 'icon': Icons.dry_cleaning_rounded},
    {'id': 'celana', 'label': 'Pants', 'icon': Icons.straighten_rounded},
    {'id': 'jaket', 'label': 'Jackets', 'icon': Icons.ac_unit_rounded},
    {'id': 'aksesoris', 'label': 'Accessories', 'icon': Icons.watch_rounded},
    {'id': 'sepatu', 'label': 'Shoes', 'icon': Icons.hiking_rounded},
  ];

  static const List<String> _sortOptions = [
    'Terbaru', 'Harga Terendah', 'Harga Tertinggi', 'Populer',
  ];

  late String _selectedCategory;
  String _selectedSort = 'Terbaru';
  late AnimationController _filterAnim;

  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _showSort = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
    _filterAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fetchProducts();
  }

  @override
  void dispose() {
    _filterAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      // Build URL dengan query param kategori
      String url = "http://outfit.web.id/api/products";
      final params = <String, String>{};
      if (_selectedCategory != 'all') params['kategori'] = _selectedCategory;
      // Sort
      switch (_selectedSort) {
        case 'Harga Terendah': params['sort'] = 'harga_asc'; break;
        case 'Harga Tertinggi': params['sort'] = 'harga_desc'; break;
        case 'Populer': params['sort'] = 'populer'; break;
        default: params['sort'] = 'terbaru';
      }
      if (params.isNotEmpty) {
        url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await http.get(Uri.parse(url),
          headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _products = data['data'] ?? []);
      } else {
        setState(() => _hasError = true);
      }
    } catch (_) {
      setState(() => _hasError = true);
    }
    setState(() => _isLoading = false);
  }

  void _changeCategory(String id) {
    if (_selectedCategory == id) return;
    setState(() => _selectedCategory = id);
    _fetchProducts();
  }

  void _changeSort(String sort) {
    setState(() { _selectedSort = sort; _showSort = false; });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fog,
      appBar: AppBar(
        backgroundColor: AppTheme.fog,
        title: const Text('KATEGORI'),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _showSort = !_showSort),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('SORT', style: AppTheme.labelCaps),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _showSort ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ),
              ]),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort dropdown
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _showSort
                ? Container(
                    color: AppTheme.canvas,
                    child: Column(
                      children: _sortOptions.map((opt) => InkWell(
                        onTap: () => _changeSort(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(opt, style: AppTheme.bodyMedium.copyWith(
                              fontWeight: _selectedSort == opt ? FontWeight.w700 : FontWeight.w400,
                            )),
                            if (_selectedSort == opt)
                              const Icon(Icons.check_rounded, size: 18, color: AppTheme.ink),
                          ]),
                        ),
                      )).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Category chips horizontal scroll
          Container(
            color: AppTheme.canvas,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return GestureDetector(
                        onTap: () => _changeCategory(cat['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.ink : AppTheme.fog,
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(cat['icon'] as IconData,
                              size: 14,
                              color: isSelected ? Colors.white : AppTheme.stone,
                            ),
                            const SizedBox(width: 6),
                            Text(cat['label'] as String,
                              style: AppTheme.labelCaps.copyWith(
                                color: isSelected ? Colors.white : AppTheme.stone,
                                fontSize: 11,
                              ),
                            ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 0),
              ],
            ),
          ),

          // Results count
          if (!_isLoading && !_hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('${_products.length} products found', style: AppTheme.bodySmall),
            ),

          // Product grid
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: _gridDelegate,
        itemCount: 6,
        itemBuilder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: double.infinity)),
          const SizedBox(height: 8),
          ShimmerBox(width: 100, height: 13),
          const SizedBox(height: 5),
          ShimmerBox(width: 70, height: 13),
        ]),
      );
    }
    if (_hasError) return EmptyState(
      icon: Icons.wifi_off_rounded, title: 'CONNECTION ERROR', subtitle: '',
      actionLabel: 'RETRY', onAction: _fetchProducts,
    );
    if (_products.isEmpty) return EmptyState(
      icon: Icons.search_off_rounded, title: 'NO PRODUCTS',
      subtitle: 'No products in this category yet.',
    );

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: AppTheme.ink,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        gridDelegate: _gridDelegate,
        itemCount: _products.length,
        itemBuilder: (_, i) => _CategoryProductCard(product: _products[i]),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount get _gridDelegate =>
    const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, childAspectRatio: 0.54,
      crossAxisSpacing: 10, mainAxisSpacing: 20,
    );
}

class _CategoryProductCard extends StatefulWidget {
  final dynamic product;
  const _CategoryProductCard({required this.product});

  @override
  State<_CategoryProductCard> createState() => _CategoryProductCardState();
}

class _CategoryProductCardState extends State<_CategoryProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: widget.product)));
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Container(
                width: double.infinity, color: AppTheme.fog,
                child: Image.network(
                  widget.product['gambar_url'] ?? '',
                  fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: AppTheme.mist)),
                ),
              ),
              Positioned(
                top: 8, right: 8,
                child: WishlistHeartButton(product: Map<String, dynamic>.from(widget.product)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(widget.product['nama'] ?? '',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('IDR ${widget.product['harga'] ?? 0}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.ink)),
        ]),
      ),
    );
  }
}