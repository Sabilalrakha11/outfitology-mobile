import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_profile_screen.dart'; // 🚨 Ini udah gue import ya!

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = false;

  // FUNGSI BUAT MASUKIN KE KERANJANG
  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
    });

    // 🚨 GANTI PAKAI IP LAPTOP LU YANG KEMAREN YA! (Misal: 192.168.x.x)
    final String apiUrl = "http://127.0.0.1:8000/api/cart"; 

    // Ambil Token dari memori HP
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hayo, kamu belum login cuy!"), backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token", 
        },
        body: jsonEncode({
          "product_id": widget.product["id"],
          "qty": 1, 
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Berhasil!'), backgroundColor: Colors.green),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${data['message']}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error koneksi: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔥 FUNGSI BUAT PINDAH KE PROFIL TOKO 🔥
  void _goToStoreProfile(dynamic store) {
    if (store != null && store['id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoreProfileScreen(storeId: store['id']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data toko tidak lengkap!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 NGAMBIL DATA TOKO DARI PRODUCT 🔥
    final store = widget.product['store'];

    return Scaffold(
      appBar: AppBar(title: const Text('DETAIL'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR PRODUK
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(widget.product["gambar_url"] ?? 'https://via.placeholder.com/400'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA DAN HARGA PRODUK
                  Text(
                    widget.product["nama"] ?? 'Produk',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Rp ${widget.product["harga"] ?? 0}",
                    style: const TextStyle(fontSize: 20, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  // ==========================================
                  // 🔥 KOTAK INFO TOKO (SELLER) 🔥
                  // ==========================================
                  const Divider(thickness: 5, color: Color(0xFFEEEEEE)), // Garis tebal pembatas
                  InkWell(
                    // 🔥 PANGGIL FUNGSI PINDAH HALAMAN 🔥
                    onTap: () => _goToStoreProfile(store),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.storefront, color: Colors.grey, size: 30),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store != null ? store['nama_toko'] ?? 'Toko Tidak Diketahui' : 'Toko Tidak Diketahui',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.blue, size: 14),
                                    SizedBox(width: 5),
                                    Text("Terverifikasi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0A192F)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                            // 🔥 PANGGIL FUNGSI PINDAH HALAMAN JUGA 🔥
                            onPressed: () => _goToStoreProfile(store),
                            child: const Text("KUNJUNGI", style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const Divider(thickness: 5, color: Color(0xFFEEEEEE)), // Garis tebal pembatas
                  // ==========================================

                  const SizedBox(height: 10),
                  const Text("DESKRIPSI PRODUK", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(
                    widget.product["deskripsi"] ?? "Tidak ada deskripsi",
                    style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A192F),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          onPressed: _isLoading ? null : _addToCart, 
          child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("ADD TO CART", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}