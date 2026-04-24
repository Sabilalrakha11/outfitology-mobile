import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_screen.dart';

class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  List<dynamic> _products = [];
  bool _isLoadingProducts = true;
  List<dynamic> _incomingOrders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _fetchMyProducts(); 
    _fetchIncomingOrders(); 
  }

  // API NARIK PRODUK
  Future<void> _fetchMyProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://192.168.0.104:8000/api/my-store/products"), // 🚨 IP LU
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          _products = jsonDecode(response.body)['data'];
          _isLoadingProducts = false;
        });
      } else {
        setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  // API NARIK PESANAN
  Future<void> _fetchIncomingOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/my-store/orders"), // 🚨 IP LU
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          _incomingOrders = jsonDecode(response.body)['data'];
          _isLoadingOrders = false;
        });
      } else {
        setState(() => _isLoadingOrders = false);
      }
    } catch (e) {
      setState(() => _isLoadingOrders = false);
    }
  }

  // 🔥 API KIRIM RESI KE LARAVEL 🔥
  Future<void> _submitResi(int orderId, String resi) async {
    setState(() => _isLoadingOrders = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("http://outfit.cicd.my.id/api/my-store/orders/$orderId/resi"), // 🚨 IP LU
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
        body: {"resi": resi}, // Bawa data resi
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resi diinput! Paket meluncur 🚀")));
        _fetchIncomingOrders(); // Refresh data pesanan otomatis
      } else {
        setState(() => _isLoadingOrders = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response.body}")));
      }
    } catch (e) {
      setState(() => _isLoadingOrders = false);
    }
  }

  // 🔥 MUNCULIN POP-UP INPUT RESI 🔥
  void _showResiDialog(int orderId) {
    TextEditingController resiController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Input Nomor Resi", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: resiController,
            decoration: const InputDecoration(hintText: "Contoh: JNE12345678", filled: true, fillColor: Color(0xFFF4F4F4)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F)),
              onPressed: () {
                if (resiController.text.isEmpty) return;
                Navigator.pop(context); // Tutup pop-up
                _submitResi(orderId, resiController.text); // Kirim resinya
              },
              child: const Text("Kirim", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DASHBOARD TOKO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF0A192F),
            labelColor: Color(0xFF0A192F),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: "PRODUK SAYA"),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: "PESANAN MASUK"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1 (PRODUK)
            Scaffold(
              backgroundColor: const Color(0xFFF4F4F4),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                  setState(() => _isLoadingProducts = true);
                  _fetchMyProducts(); 
                },
                backgroundColor: const Color(0xFF0A192F),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Tambah Produk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              body: _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
                  : _products.isEmpty
                      ? const Center(child: Text("Belum ada jualan nih cuy!", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 80),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Card(
                              elevation: 2, margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80, height: 80, color: Colors.grey[200],
                                      child: Image.network(product['gambar_url'] ?? 'https://via.placeholder.com/80', fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text("Rp ${product['harga'] ?? 0}", style: const TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // TAB 2 (PESANAN MASUK)
            Scaffold(
              backgroundColor: const Color(0xFFF4F4F4),
              body: _isLoadingOrders
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
                  : _incomingOrders.isEmpty
                      ? const Center(child: Text("Belum ada pesanan masuk nih bosqu.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: _incomingOrders.length,
                          itemBuilder: (context, index) {
                            final order = _incomingOrders[index];
                            final items = order['items'] != null ? order['items'] as List<dynamic> : [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(order['order_id_midtrans'] ?? 'ID-UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(color: _getStatusColor(order['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                          child: Text((order['status'] ?? 'pending').toString().toUpperCase(), style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 25, color: Color(0xFFEEEEEE)),
                                    
                                    ...items.map((item) {
                                      final product = item['product'];
                                      if (product == null) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40, height: 40, color: Colors.grey[200],
                                              child: Image.network(product['gambar_url'] ?? '', fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text("${item['qty']} x Rp ${item['price']}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),

                                    // 🔥 TOMBOL SAKTI: MUNCUL KALO STATUSNYA PENDING 🔥
                                    if (order['status'] == 'pending' || order['status'] == 'dikemas') ...[
                                      const Divider(height: 25, color: Color(0xFFEEEEEE)),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0A192F),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          ),
                                          onPressed: () => _showResiDialog(order['id']),
                                          child: const Text("INPUT RESI & KIRIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ] 
                                    // 🔥 TAMPILIN NOMOR RESI KALO UDAH DIKIRIM 🔥
                                    else if (order['resi'] != null) ...[
                                      const Divider(height: 25, color: Color(0xFFEEEEEE)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("No. Resi Pengiriman:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          Text(order['resi'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A192F), fontSize: 14)),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}