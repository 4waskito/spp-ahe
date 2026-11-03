import 'package:dio/dio.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  /// GET /api/admin/dashboard
  /// Returns: { total_siswa, total_pendapatan, pending_verifikasi, tagihan_belum_lunas }
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/dashboard',
      );
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal memuat dashboard admin.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi admin telah berakhir. Silakan login ulang.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Tidak dapat terhubung ke server. Pastikan server aktif.',
        );
      }
      throw Exception('Gagal memuat dashboard: ${e.message}');
    }
  }

  /// GET /api/admin/pembayaran
  /// Returns list of payment records with joined siswa + tagihan data
  Future<List<Map<String, dynamic>>> getPembayaran() async {
    try {
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/pembayaran',
      );
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal memuat data pembayaran.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi admin telah berakhir. Silakan login ulang.');
      }
      throw Exception('Gagal memuat pembayaran: ${e.message}');
    }
  }

  /// GET /api/admin/export-excel?periode=...
  Future<Map<String, dynamic>> exportExcel({String? periode}) async {
    try {
      final query = (periode != null &&
              periode.trim().isNotEmpty &&
              periode.toLowerCase() != 'semua')
          ? '?periode=${Uri.encodeComponent(periode.trim())}'
          : '';
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/export-excel$query',
      );
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception(data['message'] ?? 'Gagal membuat file Excel.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
            e.response?.data['message'] ?? 'Gagal membuat file Excel.');
      }
      throw Exception('Gagal membuat file Excel: ${e.message}');
    }
  }

  /// Get Report View HTML URL for WebView / Browser PDF printing
  String getReportViewUrl({String? periode}) {
    final query = (periode != null &&
            periode.trim().isNotEmpty &&
            periode.toLowerCase() != 'semua')
        ? '?periode=${Uri.encodeComponent(periode.trim())}'
        : '';
    final root = AppConstants.baseUrl
        .replaceAll('/index.php/api', '')
        .replaceAll('/api', '');
    return '$root/public/index.php/api/owner/report-view$query';
  }

  /// Resolve full download URL for generated export files
  String resolveExportDownloadUrl(String filename) {
    final root = AppConstants.baseUrl
        .replaceAll('/index.php/api', '')
        .replaceAll('/api', '');
    return '$root/public/exports/$filename';
  }

  /// POST /api/admin/pembayaran/approve/{id}
  Future<String> approvePembayaran(String id) async {
    try {
      final response = await _api.client.post(
        '${AppConstants.baseUrl}/admin/pembayaran/approve/$id',
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Pembayaran berhasil diapprove!';
      }
      throw Exception(data['message'] ?? 'Gagal approve pembayaran.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['messages']?['error'] ??
              e.response?.data['message'] ??
              'Gagal approve pembayaran.',
        );
      }
      throw Exception('Gagal approve pembayaran: ${e.message}');
    }
  }

  /// POST /api/admin/pembayaran/reject/{id}
  Future<String> rejectPembayaran(String id) async {
    try {
      final response = await _api.client.post(
        '${AppConstants.baseUrl}/admin/pembayaran/reject/$id',
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Pembayaran telah ditolak.';
      }
      throw Exception(data['message'] ?? 'Gagal menolak pembayaran.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['messages']?['error'] ??
              e.response?.data['message'] ??
              'Gagal menolak pembayaran.',
        );
      }
      throw Exception('Gagal menolak pembayaran: ${e.message}');
    }
  }

  /// GET /api/admin/tagihan
  Future<List<Map<String, dynamic>>> getTagihan() async {
    try {
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/tagihan',
      );
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal memuat tagihan.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi admin telah berakhir. Silakan login ulang.');
      }
      throw Exception('Gagal memuat tagihan: ${e.message}');
    }
  }

  /// POST /api/admin/tagihan/generate
  Future<String> generateTagihan(String periode, String jatuhTempo) async {
    try {
      final response = await _api.client.post(
        '${AppConstants.baseUrl}/admin/tagihan/generate',
        data: {'periode': periode, 'jatuh_tempo': jatuhTempo},
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Generate tagihan berhasil!';
      }
      throw Exception(data['message'] ?? 'Gagal generate tagihan.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal generate tagihan.',
        );
      }
      throw Exception('Gagal generate tagihan: ${e.message}');
    }
  }

  /// DELETE /api/admin/tagihan/{id}
  Future<String> deleteTagihan(String id) async {
    try {
      final response = await _api.client.delete(
        '${AppConstants.baseUrl}/admin/tagihan/$id',
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Tagihan berhasil dihapus.';
      }
      throw Exception(data['message'] ?? 'Gagal menghapus tagihan.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal menghapus tagihan.',
        );
      }
      throw Exception('Gagal menghapus tagihan: ${e.message}');
    }
  }

  /// GET /api/admin/siswa
  Future<List<Map<String, dynamic>>> getSiswa() async {
    try {
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/siswa',
      );
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal memuat data siswa.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi admin telah berakhir. Silakan login ulang.');
      }
      throw Exception('Gagal memuat siswa: ${e.message}');
    }
  }

  /// GET /api/admin/paket
  Future<List<Map<String, dynamic>>> getPaket() async {
    try {
      final response = await _api.client.get(
        '${AppConstants.baseUrl}/admin/paket',
      );
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal memuat paket SPP.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi admin telah berakhir. Silakan login ulang.');
      }
      throw Exception('Gagal memuat paket: ${e.message}');
    }
  }

  /// POST /api/admin/siswa
  Future<String> createSiswa(Map<String, dynamic> payload) async {
    try {
      final response = await _api.client.post(
        '${AppConstants.baseUrl}/admin/siswa',
        data: payload,
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Siswa berhasil ditambahkan!';
      }
      throw Exception(data['message'] ?? 'Gagal menambahkan siswa.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal menambahkan siswa.',
        );
      }
      throw Exception('Gagal menambahkan siswa: ${e.message}');
    }
  }

  /// PUT /api/admin/siswa/{nis}
  Future<String> updateSiswa(String nis, Map<String, dynamic> payload) async {
    try {
      final response = await _api.client.put(
        '${AppConstants.baseUrl}/admin/siswa/$nis',
        data: payload,
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Data siswa berhasil diperbarui!';
      }
      throw Exception(data['message'] ?? 'Gagal memperbarui siswa.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal memperbarui siswa.',
        );
      }
      throw Exception('Gagal memperbarui siswa: ${e.message}');
    }
  }

  /// DELETE /api/admin/siswa/{nis}
  Future<String> deleteSiswa(String nis) async {
    try {
      final response = await _api.client.delete(
        '${AppConstants.baseUrl}/admin/siswa/$nis',
      );
      final data = response.data;
      if (data['status'] == true) {
        return data['message'] ?? 'Data siswa berhasil dihapus.';
      }
      throw Exception(data['message'] ?? 'Gagal menghapus siswa.');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal menghapus siswa.',
        );
      }
      throw Exception('Gagal menghapus siswa: ${e.message}');
    }
  }
}
