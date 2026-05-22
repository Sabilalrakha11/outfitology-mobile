import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'config/api_config.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      // ✅ PERBAIKAN 1: pakai ApiConfig + timeout 10 detik
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/products"),
        headers: {"Accept": "application/json"},
      ).timeout(
        const Duration(seconds: 10), // ← kalau >10 detik langsung error, tidak loading selamanya
        onTimeout: () {
          throw Exception('Request timeout — server tidak merespons');
        },
      );

      // ✅ PERBAIKAN 2: print untuk debug (hapus setelah selesai debug)
      print('Status produk: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ PERBAIKAN 3: handle kalau data['data'] null
        final List<dynamic> products = data['data'] ?? [];

        setState(() {
          _allProducts = products;
          _filteredProducts = products;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      // ✅ PERBAIKAN 4: print error spesifik
      print('Error fetch produk: $e');
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    setState(() {
      _filteredProducts = keyword.isEmpty
          ? _allProducts
          : _allProducts.where((p) =>
              p["nama"].toString().toLowerCase().contains(keyword.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('OUTFITOLOGY', style: AppTheme.headingBold.copyWith(letterSpacing: 3)),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.notifications_none_rounded, color: AppTheme.ink, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _runFilter,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: AppTheme.bodySmall,
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.stone, size: 20),
          filled: true,
          fillColor: AppTheme.fog,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_hasError) return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'CONNECTION ERROR',
      subtitle: 'Unable to load products. Check your network.',
      actionLabel: 'TRY AGAIN',
      onAction: _fetchProducts,
    );
    if (_filteredProducts.isEmpty) return const EmptyState(
      icon: Icons.search_off_rounded,
      title: 'PRODUK BELUM ADA',
      subtitle: 'Belum ada produk yang ditambahkan.',
    );

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: AppTheme.ink,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('NEW ARRIVALS', style: AppTheme.labelCaps),
                  Text('${_filteredProducts.length} items', style: AppTheme.bodySmall),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(product: _filteredProducts[index]),
                childCount: _filteredProducts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.fog,
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('ESSENTIAL', style: AppTheme.labelCaps),
          const SizedBox(height: 4),
          Text('WEAR.', style: AppTheme.displayMedium.copyWith(fontSize: 32, height: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.ink,
            child: Text('SHOP NOW', style: AppTheme.buttonText.copyWith(fontSize: 11, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.52, crossAxisSpacing: 12, mainAxisSpacing: 24,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: double.infinity, height: 200),
            const SizedBox(height: 10),
            ShimmerBox(width: 120, height: 14),
            const SizedBox(height: 6),
            ShimmerBox(width: 80, height: 14),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT CARD — tidak ada perubahan dari sebelumnya
// ============================================================
class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: widget.product),
        ));
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppTheme.fog,
                    child: Image.network(
                      widget.product['gambar_url'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported_outlined, color: AppTheme.mist, size: 32),
                      ),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const ShimmerBox(width: double.infinity, height: double.infinity);
                      },
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _isWishlisted = !_isWishlisted),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isWishlisted ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          key: ValueKey(_isWishlisted),
                          size: 20,
                          color: _isWishlisted ? Colors.red.shade400 : Colors.white,
                          shadows: const [Shadow(blurRadius: 8, color: Colors.black26)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.product['nama'] ?? '',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'IDR ${widget.product['harga'] ?? 0}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.ink),
            ),
          ],
        ),
      ),
    );
  }
}