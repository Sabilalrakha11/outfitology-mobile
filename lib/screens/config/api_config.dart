// lib/config/api_config.dart
// BUAT FILE BARU di lokasi ini

class ApiConfig {
  // Ganti sesuai kondisi:
  // - Kalau develop pakai HP fisik/emulator di WiFi yang sama → pakai IP laptop
  // - Kalau sudah deploy ke server → pakai domain

  static const String baseUrl = "https://outfitku.web.id/api";
  // Ganti 103.174.237.196 dengan IP server lo (cek dengan: ifconfig | grep inet)

  // Cara cari IP server di Mac:
  // Buka terminal → ketik: ipconfig getifaddr en0
  // Hasilnya seperti: 103.174.237.196
}