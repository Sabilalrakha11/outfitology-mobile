import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Import ini buat ambil token
import 'product_detail_screen.dart'; 

class StoreProfileScreen extends StatefulWidget {
  final int storeId; 

  const StoreProfileScreen({super.key, required this.storeId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Map<String, dynamic>? _storeData;
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreProfile();
  }

  // 🔥 FUNGSI NARIK DATA TOKO & PRODUKNYA (UDAH PAKE TOKEN) 🔥
  Future<void> _fetchStoreProfile() async {
    // Ambil token dulu cuy!
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      // 🚨 GANTI IP ADDRESS KALO PERLU 🚨
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/stores/${widget.storeId}/profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token" // 🔥 Ini karcisnya biar ga diusir Laravel!
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _storeData = data['store'];
          _products = data['products'];
          _isLoading = false;
        });
      } else {
        print("Gagal ngambil data: ${response.body}"); 
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error koneksi: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PROFIL TOKO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
          : _storeData == null
              ? const Center(child: Text("Toko tidak ditemukan cuy!"))
              : CustomScrollView(
                  slivers: [
                    // ==========================================
                    // BAGIAN HEADER (BANNER TOKO)
                    // ==========================================
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F4F4),
                          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.storefront, size: 40, color: Colors.grey),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _storeData!['nama_toko'] ?? 'Toko Misterius',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.blue, size: 16),
                                SizedBox(width: 5),
                                Text("Terverifikasi", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _storeData!['deskripsi'] ?? 'Toko ini belum punya deskripsi cuy.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // ==========================================
                    // JUDUL DAFTAR PRODUK
                    // ==========================================
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Semua Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // ==========================================
                    // GRID VIEW (DAFTAR BARANG YANG DIJUAL TOKO INI)
                    // ==========================================
                    _products.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Toko ini belum punya barang jualan."))),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Bikin 2 kolom ke samping
                                childAspectRatio: 0.65, // Biar kotaknya agak panjang ke bawah
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = _products[index];
                                  // Biar datanya komplit pas dilempar ke Detail Screen
                                  product['store'] = _storeData; 
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                                child: Image.network(product['gambar_url'] ?? '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 5),
                                                Text("Rp ${product['harga'] ?? 0}", style: const TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                childCount: _products.length,
                              ),
                            ),
                          ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)), // Jarak bawah
                  ],
                ),
    );
  }
}