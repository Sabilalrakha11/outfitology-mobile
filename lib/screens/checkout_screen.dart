import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> selectedItems;
  final int subTotal;

  const CheckoutScreen({super.key, required this.selectedItems, required this.subTotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  String? _selectedProvince;
  String? _selectedCity;
  String _selectedCourier = 'jne';

  List<dynamic> _layananOngkir = [];
  dynamic _selectedLayanan;

  int _ongkir = 0;
  int _totalBayar = 0;
  bool _isLoadingOngkir = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _totalBayar = widget.subTotal; 
    _loadInitialData();
  }

  // 🔥 NARIK PROVINSI & ALAMAT SAVED SEKALIGUS 🔥
  Future<void> _loadInitialData() async {
    await _fetchProvinces();
    await _fetchSavedAddress();
    setState(() => _isLoadingData = false);
  }

  Future<void> _fetchProvinces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.get(Uri.parse("http://192.168.0.104:8000/api/provinces"), headers: {"Accept": "application/json", "Authorization": "Bearer $token"});
      if (response.statusCode == 200) setState(() => _provinces = jsonDecode(response.body)['data']);
    } catch (e) { print(e); }
  }

  Future<void> _fetchCities(String provinceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.get(Uri.parse("http://192.168.0.104:8000/api/cities/$provinceId"), headers: {"Accept": "application/json", "Authorization": "Bearer $token"});
      if (response.statusCode == 200) setState(() => _cities = jsonDecode(response.body)['data']);
    } catch (e) { print(e); }
  }

  // 🔥 CEK DATABASE, KALO PUNYA ALAMAT LANGSUNG TEMBAK ONGKIR! 🔥
  Future<void> _fetchSavedAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.get(Uri.parse("http://192.168.0.104:8000/api/user"), headers: {"Accept": "application/json", "Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        if (userData['province_id'] != null && userData['city_id'] != null) {
          setState(() => _selectedProvince = userData['province_id'].toString());
          await _fetchCities(_selectedProvince!);
          setState(() => _selectedCity = userData['city_id'].toString());
          
          // LANGSUNG JALANIN HITUNG ONGKIR OTOMATIS!
          await _cekOngkir();
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> _cekOngkir() async {
    if (_selectedCity == null) return;
    setState(() { _isLoadingOngkir = true; _layananOngkir = []; _selectedLayanan = null; _ongkir = 0; _totalBayar = widget.subTotal; });
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.104:8000/api/check-cost"),
        headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"origin": "468", "destination": _selectedCity, "weight": 1000, "courier": _selectedCourier}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data != null && data.isNotEmpty) {
          setState(() {
            _layananOngkir = data;
            _selectedLayanan = data[0]; 
            _ongkir = int.parse((_selectedLayanan['price'] ?? _selectedLayanan['cost'] ?? 0).toString());
            _totalBayar = widget.subTotal + _ongkir; 
          });
        }
      }
    } catch (e) { print(e); }
    setState(() => _isLoadingOngkir = false);
  }

  Future<void> _prosesPembayaran() async {
    if (_selectedCity == null || _ongkir == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi alamat & kurir dulu cuy!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoadingOngkir = true); // Munculin loading muter
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      // 1. Tembak API Checkout di Laravel lu
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/checkout"), 
        headers: {
          "Accept": "application/json", 
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "total_bayar": _totalBayar,
          "ongkir": _ongkir,
          "kurir": _selectedCourier,
          // Ambil ID barang yang diceklis dari keranjang
          "cart_ids": widget.selectedItems.map((item) => item['id']).toList(), 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String paymentUrl = data['redirect_url']; // Link Midtrans dari Laravel

        if (!mounted) return;

        // 🔥 MUNCULIN NOTIF HIJAU GEDE KALO BERHASIL 🔥
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ BERHASIL CUY! Buka Console/Terminal buat liat link Midtransnya!"), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          )
        );

        // NGE-PRINT LINK KE TERMINAL BIAR BISA LU KLIK
        print("\n=================================================");
        print("🔥 CHECKOUT SUKSES! KLIK LINK INI BUAT BAYAR: 🔥");
        print(paymentUrl);
        print("=================================================\n");

      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Checkout: ${response.body}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Error Checkout: $e");
    }
    
    setState(() => _isLoadingOngkir = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(title: const Text('PENGIRIMAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)), centerTitle: true),
      body: _isLoadingData
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ALAMAT TUJUAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true, // 🔥 MENGHILANGKAN GARIS POLISI 🔥
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)),
              hint: const Text("Pilih Provinsi"), value: _selectedProvince,
              items: _provinces.map((prov) => DropdownMenuItem<String>(value: prov['id'].toString(), child: Text(prov['name']))).toList(),
              onChanged: (val) { 
                setState(() { _selectedProvince = val; _selectedCity = null; _cities = []; }); 
                _fetchCities(val!); 
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              isExpanded: true, // 🔥 MENGHILANGKAN GARIS POLISI 🔥
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)),
              hint: const Text("Pilih Kota"), value: _selectedCity,
              items: _cities.map((city) => DropdownMenuItem<String>(value: city['id'].toString(), child: Text(city['name']))).toList(),
              onChanged: (val) { setState(() => _selectedCity = val); _cekOngkir(); },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)),
              value: _selectedCourier,
              items: const [
                DropdownMenuItem(value: 'jne', child: Text("JNE")), DropdownMenuItem(value: 'pos', child: Text("POS Indonesia")), DropdownMenuItem(value: 'sicepat', child: Text("SiCepat")),
              ],
              onChanged: (val) { setState(() => _selectedCourier = val!); _cekOngkir(); },
            ),
            const SizedBox(height: 15),

            if (_layananOngkir.isNotEmpty) ...[
              const Text("Pilih Layanan Pengiriman", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              DropdownButtonFormField<dynamic>(
                isExpanded: true, // 🔥 MENGHILANGKAN GARIS POLISI 🔥
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)),
                value: _selectedLayanan,
                items: _layananOngkir.map((layanan) {
                  String namaLayanan = layanan['name'] ?? layanan['service'] ?? 'Layanan';
                  String etd = layanan['etd'] ?? layanan['estimate'] ?? '-';
                  int harga = int.parse((layanan['price'] ?? layanan['cost'] ?? 0).toString());
                  return DropdownMenuItem<dynamic>(
                    value: layanan,
                    child: Text("$namaLayanan (Est: $etd) - Rp $harga", style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLayanan = val;
                    _ongkir = int.parse((val['price'] ?? val['cost'] ?? 0).toString());
                    _totalBayar = widget.subTotal + _ongkir;
                  });
                },
              ),
            ],

            const SizedBox(height: 30),
            const Text("RINGKASAN PESANAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15), color: Colors.white,
              child: Column(
                children: widget.selectedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔥 MENGHILANGKAN GARIS POLISI DI NAMA BARANG 🔥
                        Expanded(child: Text("${item['product']['nama']} (x${item['qty']})", overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 10),
                        Text("Rp ${int.parse(item['product']['harga'].toString()) * int.parse(item['qty'].toString())}")
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20), color: Colors.white,
        child: _isLoadingOngkir 
        ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Subtotal: Rp ${widget.subTotal}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Ongkir: Rp $_ongkir", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Total: Rp $_totalBayar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              onPressed: _prosesPembayaran, child: const Text("BAYAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}