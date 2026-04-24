import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  
  File? _image; // Buat nyimpen gambar yang dipilih
  bool _isLoading = false; // Buat efek loading pas tombol diklik

  // 🔥 FUNGSI BUAT BUKA GALERI HP 🔥
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // 🔥 FUNGSI BUAT NGIRIM DATA KE LARAVEL 🔥
  Future<void> _submitProduct() async {
    // Validasi kalau ada yang kosong
    if (_namaController.text.isEmpty || _hargaController.text.isEmpty || _deskripsiController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua data & pilih gambar dulu cuy!")));
      return;
    }

    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      // Bikin paket pengiriman khusus (Multipart) karena ada file gambar
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse("http://outfit.cicd.my.id/api/my-store/products") // 🚨 PASTIIN IP LU BENER 🚨
      );

      // Selipin Token
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Masukin data teks
      request.fields['nama'] = _namaController.text;
      request.fields['harga'] = _hargaController.text;
      request.fields['deskripsi'] = _deskripsiController.text;

      // Masukin file gambar
      request.files.add(await http.MultipartFile.fromPath('gambar', _image!.path));

      // Kirim paketnya!
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mantap! Produk berhasil diupload! 🎉")));
        Navigator.pop(context); // Balik ke halaman dashboard
      } else {
        print("Error Laravel: ${responseData.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal upload cuy, cek terminal.")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error koneksi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('TAMBAH PRODUK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // KOTAK BUAT UPLOAD GAMBAR
            // ==========================================
            const Text("Foto Produk", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage, // Panggil fungsi buka galeri
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                // Kalau gambar udah dipilih, tampilin gambarnya. Kalau belum, tampilin icon.
                child: _image != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Klik untuk tambah foto", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 25),

            // ==========================================
            // FORM INPUT NAMA, HARGA, DESKRIPSI
            // ==========================================
            const Text("Nama Produk", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: "Contoh: Kemeja Flanel Pria",
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Harga (Rp)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Contoh: 150000",
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Jelasin bahan, ukuran, dan detail produk lu cuy...",
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            // ==========================================
            // TOMBOL SIMPAN
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _submitProduct, // Bakal disable pas lagi loading
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SIMPAN PRODUK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}