import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  String? _selectedProvince;
  String? _selectedCity;
  final TextEditingController _detailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true; // Loading buat narik data awal

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 🔥 FUNGSI BARU: NARIK PROVINSI SEKALIGUS NARIK ALAMAT USER 🔥
  Future<void> _loadInitialData() async {
    await _fetchProvinces(); // Tarik list provinsi dulu
    await _fetchSavedAddress(); // Baru cek user punya alamat atau nggak
    setState(() => _isLoadingData = false);
  }

  Future<void> _fetchProvinces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/provinces"), 
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"}
      );
      if (response.statusCode == 200) setState(() => _provinces = jsonDecode(response.body)['data']);
    } catch (e) { print(e); }
  }

  Future<void> _fetchCities(String provinceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/cities/$provinceId"), 
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"}
      );
      if (response.statusCode == 200) {
        setState(() => _cities = jsonDecode(response.body)['data']);
      }
    } catch (e) { print(e); }
  }

  // 🔥 FUNGSI NARIK ALAMAT YANG UDAH DISIMPEN USER 🔥
  Future<void> _fetchSavedAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      // Laravel by default punya endpoint /api/user buat ngambil data user yg login
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/user"), 
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"}
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Kalo usernya udah pernah ngisi alamat...
        if (userData['province_id'] != null) {
          setState(() => _selectedProvince = userData['province_id'].toString());
          
          // Tarik kota berdasarkan provinsi yang udah disimpen
          await _fetchCities(_selectedProvince!); 
          
          setState(() {
            _selectedCity = userData['city_id'].toString();
            _detailController.text = userData['detail_alamat'] ?? '';
          });
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> _saveAddress() async {
    if (_selectedCity == null || _detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Provinsi, Kota, dan Detail Alamat cuy!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("http://outfit.cicd.my.id/api/update-alamat"), 
        headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "province_id": _selectedProvince,
          "city_id": _selectedCity,
          "detail_alamat": _detailController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mantap! Alamat berhasil disimpan! 🚀"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) { print("Error: $e"); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(title: const Text('ATUR ALAMAT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)), centerTitle: true),
      body: _isLoadingData 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F)))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Provinsi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
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
            const SizedBox(height: 20),
            
            const Text("Kota/Kabupaten", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              isExpanded: true, // 🔥 MENGHILANGKAN GARIS POLISI 🔥
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)),
              hint: const Text("Pilih Kota"), value: _selectedCity,
              items: _cities.map((city) => DropdownMenuItem<String>(value: city['id'].toString(), child: Text(city['name']))).toList(),
              onChanged: (val) { setState(() => _selectedCity = val); },
            ),
            const SizedBox(height: 20),

            const Text("Detail Alamat (Jalan, RT/RW, Patokan)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _detailController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Contoh: Jl. Mawar No. 12, RT 01/RW 02.",
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F), padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("SIMPAN ALAMAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}