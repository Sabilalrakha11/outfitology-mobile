import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk mengelola data JSON

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk menangkap teks yang diketik user
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variabel untuk efek loading
  bool _isLoading = false;

  // Fungsi untuk menembak API Laravel
  Future<void> _registerUser() async {
    // Validasi form kosong
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi cuy!')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Nyalakan loading
    });

    try {
      var response = await http.post(
        Uri.parse('http://outfit.cicd.my.id/api/register'), // Endpoint Laravel
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      // Cek apakah sukses (biasanya 200 OK atau 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
        );
        // Kalau sukses, lempar balik ke halaman Login
        if (!mounted) return;
        Navigator.pop(context); 
      } else {
        // Kalau gagal (misal email udah ada), tangkap error dari Laravel
        var data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${data['message'] ?? 'Email mungkin sudah dipakai'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error koneksi: Server belum siap atau tidak ada internet')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Matikan loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAFTAR AKUN'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "JOIN OUTFITOLOGY.",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            const Text("Buat akun baru untuk mulai belanja.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            
            // Form Nama Lengkap
            TextFormField(
              controller: _nameController, // Pasang controller
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0A192F))),
              ),
            ),
            const SizedBox(height: 20),

            // Form Email
            TextFormField(
              controller: _emailController, // Pasang controller
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0A192F))),
              ),
            ),
            const SizedBox(height: 20),
            
            // Form Password
            TextFormField(
              controller: _passwordController, // Pasang controller
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0A192F))),
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Register
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                // Kalau lagi loading, tombolnya mati sementara biar gak diklik dobel
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) // Putaran loading
                    : const Text("DAFTAR SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Kembali ke Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sudah punya akun?"),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Balik ke layar Login
                  },
                  child: const Text("Login di sini", style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}