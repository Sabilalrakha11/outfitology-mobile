import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'product_detail_screen.dart';

// ============================================================
// SEARCH SCREEN — Dengan recent history, suggestions, live search
// ============================================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<dynamic> _results = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  static const _suggestions = [
    'Kaos polos', 'Kemeja flanel', 'Celana chino', 'Jaket bomber',
    'Sepatu sneakers', 'Topi baseball', 'Tas backpack', 'Hoodie',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recentSearches = prefs.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [query, ..._recentSearches.where((s) => s != query).take(9)];
    await prefs.setStringList('recent_searches', updated);
    setState(() => _recentSearches = updated);
  }

  Future<void> _removeRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches = []);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    _controller.text = query;
    _focus.unfocus();
    setState(() { _isLoading = true; _hasSearched = true; });
    await _saveRecent(query.trim());
    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/products?search=${Uri.encodeComponent(query)}"),
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        setState(() => _results = jsonDecode(response.body)['data'] ?? []);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _clear() {
    _controller.clear();
    setState(() { _results = []; _hasSearched = false; });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                style: AppTheme.bodyMedium,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Search Outfitology...',
                  hintStyle: AppTheme.bodySmall,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.stone, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clear,
                          child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.stone))
                      : null,
                  filled: true, fillColor: AppTheme.fog,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('CANCEL', style: AppTheme.labelCaps),
            ),
          ]),
        ),
      ),
      body: _hasSearched ? _buildResults() : _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('RECENT', style: AppTheme.labelCaps),
            GestureDetector(
              onTap: _clearAllRecent,
              child: Text('CLEAR', style: AppTheme.labelCaps.copyWith(color: AppTheme.stone)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._recentSearches.map((s) => InkWell(
            onTap: () => _search(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                const Icon(Icons.history_rounded, size: 18, color: AppTheme.stone),
                const SizedBox(width: 12),
                Expanded(child: Text(s, style: AppTheme.bodyMedium)),
                GestureDetector(
                  onTap: () => _removeRecent(s),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.stone),
                ),
              ]),
            ),
          )),
          const Divider(height: 24),
        ],
        const SizedBox(height: 24),
        Text('POPULAR SEARCHES', style: AppTheme.labelCaps),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _suggestions.map((s) => GestureDetector(
          onTap: () => _search(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.fog,
              border: Border.all(color: AppTheme.mist),
            ),
            child: Text(s, style: AppTheme.bodySmall.copyWith(color: AppTheme.ink)),
          ),
        )).toList()),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(color: AppTheme.ink, strokeWidth: 2));

    if (_results.isEmpty) return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.mist),
        const SizedBox(height: 16),
        Text('NO RESULTS', style: AppTheme.headingBold),
        const SizedBox(height: 8),
        Text('Try a different keyword or\ncheck the spelling.',
          style: AppTheme.bodySmall, textAlign: TextAlign.center),
      ]),
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text('${_results.length} results for "${_controller.text}"',
          style: AppTheme.bodySmall),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.54,
            crossAxisSpacing: 10, mainAxisSpacing: 20,
          ),
          itemCount: _results.length,
          itemBuilder: (_, i) {
            final p = _results[i];
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Container(color: AppTheme.fog, width: double.infinity,
                    child: Image.network(p['gambar_url'] ?? '', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined,
                          color: AppTheme.mist))),
                ),
                const SizedBox(height: 8),
                Text(p['nama'] ?? '', style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('IDR ${p['harga'] ?? 0}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.ink)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}