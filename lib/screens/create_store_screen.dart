import 'package:flutter/material.dart';

class CreateStoreScreen extends StatelessWidget {
  const CreateStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUKA TOKO GRATIS'), centerTitle: true),
      body: const Center(
        child: Text("Halaman Form Bikin Toko (Segera Hadir!)", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}