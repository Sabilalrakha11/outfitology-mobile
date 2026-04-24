import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'order_history_screen.dart'; 
import 'create_store_screen.dart'; 
import 'store_dashboard_screen.dart';
import 'edit_address_screen.dart';

// 🔥 UBAH JADI STATEFUL WIDGET BIAR BISA UPDATE DATA 🔥
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Bikin variabel buat nampung data asli
  String _userName = "Memuat nama...";
  String _userEmail = "Memuat email...";

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Narik data pas layar dibuka
  }

  // 🔥 FUNGSI NARIK DATA USER DARI LARAVEL 🔥
  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://outfit.cicd.my.id/api/user"), // API bawaan Laravel buat cek user
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['name']; // Sesuaiin sama kolom di tabel users lu
          _userEmail = data['email'];
        });
      }
    } catch (e) {
      print("Error narik profil: $e");
      setState(() {
        _userName = "Gagal memuat data";
        _userEmail = "Gagal memuat data";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PROFILE'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // INFO USER (UDAH DINAMIS / ASLI)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: const Color(0xFFF4F4F4),
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Color(0xFF0A192F), child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(height: 15),
                  Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_userEmail, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // ==========================================
            // MENU-MENU BAWAHNYA (TETEP SAMA KAYAK KEMAREN)
            // ==========================================
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.black87),
              title: const Text("Pesanan Saya", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Lacak barang yang kamu beli"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
              },
            ),
            const Divider(),
            
            // ==========================================
            // 🔥 MENU BARU: ALAMAT SAYA 🔥
            // ==========================================
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: Colors.black87),
              title: const Text("Alamat Saya", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Atur alamat pengiriman kamu"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAddressScreen()));
              },
            ),
            const Divider(), // Garis pembatas

            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.black87),
              title: const Text("Toko Saya", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Kelola produk dan pesanan masuk"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0A192F))),
                );

                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? token = prefs.getString('token');

                try {
                  final response = await http.get(
                    Uri.parse("http://outfit.cicd.my.id/api/my-store"), 
                    headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    if (data['status'] == 'ada') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreDashboardScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateStoreScreen()));
                    }
                  } else {
                    print("Error dari API: ${response.body}");
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  print("Error koneksi: $e");
                }
              },
            ),
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: () async {
                    // 🔥 JANGAN LUPA HAPUS TOKEN PAS LOGOUT 🔥
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.remove('token');

                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("LOGOUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}