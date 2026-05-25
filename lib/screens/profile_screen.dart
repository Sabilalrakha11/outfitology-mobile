import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'create_store_screen.dart';
import 'store_dashboard_screen.dart';
import 'edit_address_screen.dart';
import 'config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        // INI YANG PALING PENTING, WAJIB PAKAI ApiConfig.baseUrl
        Uri.parse('${ApiConfig.baseUrl}/user'), 
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // ... sisa kodingan setState nampilin nama & email ...
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Sesuaikan dengan variabel di kodingan kamu (misal _name atau _userName)
          // _name = data['name']; 
        });
      }
    } catch (e) {
      print("Error fetch user: $e");
    }
  }

  Future<void> _checkStore() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()) // Sesuaikan warna loadingnya kalau error
    );
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        // PAKAI ApiConfig BIAR OTOMATIS HTTPS SESUAI FILE CONFIG KAMU
        Uri.parse("${ApiConfig.baseUrl}/my-store"),
        headers: {
          "Accept": "application/json", 
          "Authorization": "Bearer $token"
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading muter-muter

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => data['status'] == 'ada' ? const StoreDashboardScreen() : const CreateStoreScreen(),
        ));
      } else {
        // Biar nggak "diem" aja kalau ada error dari server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat toko (Error ${response.statusCode})"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading kalau error jaringan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign Out', style: AppTheme.headingBold),
        content: Text('Are you sure you want to sign out?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('CANCEL', style: AppTheme.labelCaps)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('SIGN OUT', style: AppTheme.labelCaps.copyWith(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fog,
      appBar: AppBar(
        backgroundColor: AppTheme.fog,
        title: const Text('ACCOUNT'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUser,
        color: AppTheme.ink,
        child: ListView(
          children: [
            // User header card
            Container(
              color: AppTheme.canvas,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: _isLoading
                  ? Row(children: [
                      const ShimmerBox(width: 56, height: 56, borderRadius: 28),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ShimmerBox(width: 120, height: 16),
                        const SizedBox(height: 8),
                        ShimmerBox(width: 160, height: 12),
                      ]),
                    ])
                  : Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: const BoxDecoration(
                            color: AppTheme.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                              style: AppTheme.headingBold.copyWith(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(_email, style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Menu items
            _MenuSection(
              title: 'ORDERS',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  subtitle: 'Track your purchases',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MenuSection(
              title: 'SETTINGS',
              items: [
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery Address',
                  subtitle: 'Manage your addresses',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditAddressScreen())),
                ),
                _MenuItem(
                  icon: Icons.storefront_rounded,
                  label: 'My Store',
                  subtitle: 'Manage products & orders',
                  onTap: _checkStore,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.mist)),
                  child: Text('SIGN OUT', style: AppTheme.headingBold.copyWith(color: Colors.red.shade400)),
                ),
              ),
            ),
            const SizedBox(height: 48),

            Center(child: Text('OUTFITOLOGY v1.0', style: AppTheme.bodySmall)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(title, style: AppTheme.labelCaps),
        ),
        Container(
          color: AppTheme.canvas,
          child: Column(
            children: List.generate(items.length, (i) => Column(
              children: [
                items[i],
                if (i < items.length - 1) const Divider(indent: 56, height: 0),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.ink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.stone),
            ],
          ),
        ),
      ),
    );
  }
}