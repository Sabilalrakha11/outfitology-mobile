import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  // 🚨 SESUAIIN SAMA IP LAPTOP LU KAYAK KEMAREN YA!
  final String baseUrl = "http://127.0.0.1:8000/api";

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // FUNGSI NARIK DATA DARI API LARAVEL
  Future<void> _fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['data'];
          _isLoading = false;
        });
      } else {
        print("====== ERROR DARI LARAVEL ======");
        print(response.body); 
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error koneksi: $e");
    }
  }

  // BIKIN WARNA STATUS (Udah anti-null)
  Color _getStatusColor(String? status) {
    String safeStatus = status ?? 'pending';
    switch (safeStatus.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'dikemas': return Colors.blue;
      case 'dikirim': return Colors.purple;
      case 'diterima': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PESANAN SAYA'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
          : _orders.isEmpty
              ? const Center(child: Text("Belum ada riwayat pesanan cuy!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final items = order['items'] != null ? order['items'] as List<dynamic> : [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BAGIAN HEADER NOTA (ID & STATUS) - KEBAL NULL
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    order['order_id_midtrans'] ?? 'ID-TIDAK-DIKETAHUI', // 🔥 Kalo kosong, tampilin ini
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    (order['status'] ?? 'pending').toString().toUpperCase(), // 🔥 Kalo kosong, anggep pending
                                    style: TextStyle(
                                      color: _getStatusColor(order['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 30, color: Color(0xFFEEEEEE)),
                            
                            // BAGIAN DAFTAR BARANG YANG DIBELI - KEBAL NULL
                            ...items.map((item) {
                              final product = item['product'];
                              if (product == null) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: Image.network(
                                        product['gambar_url'] ?? 'https://via.placeholder.com/50', // 🔥 Kalo gambar kosong
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported), // Kalo link rusak
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)), // 🔥 Kalo nama kosong
                                          Text("${item['qty'] ?? 1} x Rp ${item['price'] ?? 0}", style: const TextStyle(color: Colors.black54, fontSize: 13)), 
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            const Divider(height: 30, color: Color(0xFFEEEEEE)),
                            
                            // BAGIAN TOTAL HARGA & RESI - KEBAL NULL
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Total Belanja", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text("Rp ${order['total_harga'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                if (order['resi'] != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text("No. Resi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text(order['resi'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}