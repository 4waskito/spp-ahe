import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'SPP Mobile';
  static const String appVersion = '1.0.0';

  // Key for local storage
  static const String keyToken = 'spp_jwt_token';
  static const String keyUser = 'spp_user_data';
  static const String keyCustomBaseUrl = 'spp_custom_base_url';

  // Default server URLs
  // 10.0.2.2 is Android Emulator loopback to Host PC
  // 192.168.1.4 is current host Wi-Fi IP for physical devices
  static const String defaultEmulatorUrl =
      'http://10.0.2.2/pembayaran_spp_revisi/public/index.php/api';
  static const String defaultLanUrl =
      'http://192.168.1.4/pembayaran_spp_revisi/public/index.php/api';
  static const String defaultLocalhostUrl =
      'http://localhost/pembayaran_spp_revisi/public/index.php/api';

  static String _currentBaseUrl = defaultLocalhostUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyCustomBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      _currentBaseUrl = saved.trim();
    } else {
      _currentBaseUrl = kIsWeb ? defaultLocalhostUrl : defaultEmulatorUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    _currentBaseUrl = newUrl.trim();
    await prefs.setString(keyCustomBaseUrl, _currentBaseUrl);
  }

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String profileEndpoint = '/siswa/profile';
  static const String tagihanEndpoint = '/siswa/tagihan';
  static const String bayarEndpoint = '/siswa/bayar';
  static const String riwayatEndpoint = '/siswa/riwayat';
  static const String midtransSnapEndpoint = '/siswa/midtrans/snap-token';
  static const String midtransStatusEndpoint = '/siswa/midtrans/status';

  // Bank Destination List for manual transfer
  static const List<Map<String, String>> bankList = [
    {
      'bank': 'Bank BCA',
      'rekening': '8830 1928 33',
      'atas_nama': 'Lembaga SPP Bimbel',
      'logo_text': 'BCA',
    },
    {
      'bank': 'Bank Mandiri',
      'rekening': '137 00 1928374 1',
      'atas_nama': 'Lembaga SPP Bimbel',
      'logo_text': 'MANDIRI',
    },
    {
      'bank': 'Bank BRI',
      'rekening': '0123 01 098765 50 8',
      'atas_nama': 'Lembaga SPP Bimbel',
      'logo_text': 'BRI',
    },
  ];
}
