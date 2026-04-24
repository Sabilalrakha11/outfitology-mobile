import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allProducts = []; // Nyimpen semua data asli dari Laravel
  List<dynamic> _filteredProducts = []; // Nyimpen data yang udah di-search/disaring
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // FUNGSI NARIK DATA DARI LARAVEL
  Future<void> _fetchProducts() async {
    try {
      // 🚨 GANTI IP SESUAI YANG LU PAKE SEKARANG 🚨
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/api/products"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allProducts = data['data'];
          _filteredProducts = _allProducts; // Awalnya tampilin semua
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error koneksi: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🔥 FUNGSI SAKTI BUAT SEARCH INSTAN 🔥
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allProducts; // Kalo kolom search kosong, tampilin semua barang
    } else {
      results = _allProducts
          .where((product) =>
              product["nama"].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList(); // Cari barang yang namanya ada unsur ketikan lu
    }

    // Refresh layar pake data yang udah disaring
    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('OUTFITOLOGY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 🔥 SEARCH BAR BARU DI ATAS 🔥
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _runFilter(value), // Pas lu ngetik, dia langsung nyortir!
                    decoration: InputDecoration(
                      hintText: "Cari produk kesukaanmu...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0), // Biar gak terlalu lebar ke bawah
                    ),
                  ),
                ),

                // ==========================================
                // TEKS HEADER (NEW ARRIVALS)
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFFF4F4F4),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("NEW ARRIVALS", style: TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 12)),
                      SizedBox(height: 5),
                      Text("ESSENTIAL\nWEAR.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
                    ],
                  ),
                ),

                // ==========================================
                // GRID PRODUK (YANG UDAH DI-FILTER SAMA SEARCH)
                // ==========================================
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text("Yahh, barangnya gak ketemu cuy! 😢"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55, // Nyesuaiin ukuran foto baju lu yang panjang
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: Colors.grey[200]),
                                      child: Image.network(product['gambar_url'] ?? '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text("Rp ${product['harga'] ?? 0}", style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}