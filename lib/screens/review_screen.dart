import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// ============================================================
// REVIEW SCREEN — Tulis & lihat ulasan produk
// ============================================================
class ReviewScreen extends StatefulWidget {
  final int productId;
  final String productName;
  const ReviewScreen({super.key, required this.productId, required this.productName});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchReviews();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/products/${widget.productId}/reviews"),
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reviews = data['reviews'] ?? [];
          _stats = data['stats'];
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<double>(0, (sum, r) => sum + (r['rating'] ?? 0)) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fog,
      appBar: AppBar(
        backgroundColor: AppTheme.fog,
        title: const Text('REVIEWS'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.ink, labelColor: AppTheme.ink,
          unselectedLabelColor: AppTheme.stone,
          labelStyle: AppTheme.labelCaps,
          tabs: const [Tab(text: 'ALL REVIEWS'), Tab(text: 'WRITE REVIEW')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ReviewListTab(
            reviews: _reviews, isLoading: _isLoading,
            avgRating: _avgRating, stats: _stats,
            onRefresh: _fetchReviews,
          ),
          _WriteReviewTab(
            productId: widget.productId,
            onSubmitted: () { _fetchReviews(); _tabs.animateTo(0); },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: List reviews
// ============================================================
class _ReviewListTab extends StatelessWidget {
  final List<dynamic> reviews;
  final bool isLoading;
  final double avgRating;
  final Map<String, dynamic>? stats;
  final VoidCallback onRefresh;

  const _ReviewListTab({
    required this.reviews, required this.isLoading,
    required this.avgRating, required this.stats, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.ink));
    if (reviews.isEmpty) return const EmptyState(
      icon: Icons.rate_review_outlined,
      title: 'NO REVIEWS YET',
      subtitle: 'Be the first to review this product.',
    );

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.ink,
      child: ListView(children: [
        // Rating summary
        Container(
          color: AppTheme.canvas, padding: const EdgeInsets.all(24),
          child: Row(children: [
            // Big rating number
            Column(children: [
              Text(avgRating.toStringAsFixed(1),
                style: AppTheme.displayLarge.copyWith(fontSize: 48, height: 1)),
              _StarRow(rating: avgRating, size: 14),
              const SizedBox(height: 4),
              Text('${reviews.length} reviews', style: AppTheme.bodySmall),
            ]),
            const SizedBox(width: 32),
            // Rating bars
            Expanded(child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = reviews.where((r) => (r['rating'] ?? 0) == star).length;
                final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text('$star', style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: AppTheme.mist,
                          valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(width: 20, child: Text('$count', style: AppTheme.bodySmall.copyWith(fontSize: 11))),
                  ]),
                );
              }).toList(),
            )),
          ]),
        ),
        const SizedBox(height: 8),

        // Review cards
        ...reviews.map((r) => Container(
          color: AppTheme.canvas, margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 18, backgroundColor: AppTheme.fog,
                child: Text(
                  (r['user']?['name'] ?? 'U')[0].toUpperCase(),
                  style: AppTheme.headingBold.copyWith(fontSize: 14),
                )),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['user']?['name'] ?? 'Anonymous',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_formatDate(r['created_at']), style: AppTheme.bodySmall.copyWith(fontSize: 11)),
              ])),
              _StarRow(rating: (r['rating'] ?? 0).toDouble(), size: 13),
            ]),
            const SizedBox(height: 10),
            if (r['comment'] != null && r['comment'].toString().isNotEmpty)
              Text(r['comment'].toString(),
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.stone, height: 1.6)),
          ]),
        )).toList(),
      ]),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}

// ============================================================
// TAB 2: Write review
// ============================================================
class _WriteReviewTab extends StatefulWidget {
  final int productId;
  final VoidCallback onSubmitted;
  const _WriteReviewTab({required this.productId, required this.onSubmitted});

  @override
  State<_WriteReviewTab> createState() => _WriteReviewTabState();
}

class _WriteReviewTabState extends State<_WriteReviewTab> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() { _commentController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a rating.'), backgroundColor: AppTheme.ink));
      return;
    }
    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse("http://outfit.cicd.my.id/api/products/${widget.productId}/reviews"),
        headers: {"Accept": "application/json", "Content-Type": "application/json",
          "Authorization": "Bearer $token"},
        body: jsonEncode({"rating": _rating, "comment": _commentController.text}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Review submitted!', style: AppTheme.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: Colors.green.shade700));
        widget.onSubmitted();
      }
    } catch (_) {}
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(color: AppTheme.canvas, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR RATING', style: AppTheme.labelCaps),
            const SizedBox(height: 16),
            // Star rating picker
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: AnimatedScale(
                  scale: _rating > i ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _rating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40, color: _rating > i ? Colors.amber : AppTheme.mist,
                    ),
                  ),
                ),
              );
            })),
            const SizedBox(height: 8),
            Center(child: Text(
              ['', 'Terrible', 'Poor', 'Okay', 'Good', 'Excellent'][_rating],
              style: AppTheme.labelCaps.copyWith(
                color: _rating > 3 ? Colors.green : (_rating > 1 ? Colors.orange : Colors.red)),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        Container(color: AppTheme.canvas, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR COMMENT', style: AppTheme.labelCaps),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5, maxLength: 500, style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Share your experience with this product...',
                hintStyle: AppTheme.bodySmall, filled: true, fillColor: AppTheme.fog,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity,
          child: PrimaryButton(
            label: 'SUBMIT REVIEW',
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
          )),
      ]),
    );
  }
}

// Reusable star row widget
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
      if (i < rating.floor()) return Icon(Icons.star_rounded, size: size, color: Colors.amber);
      if (i < rating) return Icon(Icons.star_half_rounded, size: size, color: Colors.amber);
      return Icon(Icons.star_outline_rounded, size: size, color: AppTheme.mist);
    }));
  }
}