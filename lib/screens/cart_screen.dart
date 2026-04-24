import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'checkout_screen.dart'; // Import layar pengiriman

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  List<int> _selectedItemIds = []; // Nyimpen ID barang yang diceklis
  bool _isLoading = true;
  int _subTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/cart"), // 🚨 Pastiin IP ini bener
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          _cartItems = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) { 
      // 🔥 INI TOA-NYA UDAH TERPASANG BOSQU 🔥
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Koneksi cuy! : $e"), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5), // Tampil 5 detik biar sempet dibaca
        )
      );
      setState(() => _isLoading = false); 
    }
  }

  // FUNGSI NGITUNG TOTAL BERDASARKAN YANG DICEKLIS AJA
  void _calculateSubTotal() {
    int tempTotal = 0;
    for (var item in _cartItems) {
      if (_selectedItemIds.contains(item['id'])) {
        tempTotal += (int.parse(item['product']['harga'].toString()) * int.parse(item['qty'].toString()));
      }
    }
    setState(() { _subTotal = tempTotal; });
  }

  // FUNGSI CEKLIS BARANG
  void _toggleSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      _calculateSubTotal();
    });
  }

  // FUNGSI TOMBOL PLUS MINUS QTY
  void _updateQty(int index, bool isIncrement) {
    setState(() {
      int currentQty = int.parse(_cartItems[index]['qty'].toString());
      if (isIncrement) {
        _cartItems[index]['qty'] = currentQty + 1;
      } else {
        if (currentQty > 1) {
          _cartItems[index]['qty'] = currentQty - 1;
        }
      }
      _calculateSubTotal();
    });
  }

  // FUNGSI KE HALAMAN CHECKOUT (PENGIRIMAN)
  void _goToCheckout() {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ceklis minimal 1 barang dulu bosqu!"), backgroundColor: Colors.red));
      return;
    }

    // Filter barang yang diceklis aja buat dikirim ke halaman Checkout
    List<dynamic> itemsToCheckout = _cartItems.where((item) => _selectedItemIds.contains(item['id'])).toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(selectedItems: itemsToCheckout, subTotal: _subTotal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(title: const Text('SHOPPING CART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
          : _cartItems.isEmpty
              ? const Center(child: Text("Keranjang kosong cuy!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    final product = item['product'];
                    final isSelected = _selectedItemIds.contains(item['id']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            // CHECKBOX
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF0A192F),
                              onChanged: (val) => _toggleSelection(item['id']),
                            ),
                            Container(width: 70, height: 70, color: Colors.grey[200], child: Image.network(product['gambar_url'] ?? '', fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 5),
                                  Text("Rp ${product['harga'] ?? 0}", style: const TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  // TOMBOL PLUS MINUS
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _updateQty(index, false),
                                        child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.remove, size: 16)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text("${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      InkWell(
                                        onTap: () => _updateQty(index, true),
                                        child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.add, size: 16)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20), color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Bayar", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Rp $_subTotal", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              onPressed: _goToCheckout, child: const Text("CHECKOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}