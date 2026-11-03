import 'package:dio/dio.dart';
import '../config/app_constants.dart';
import '../models/tagihan_model.dart';
import '../models/pembayaran_model.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _api.client.get(AppConstants.profileEndpoint);
      if (response.data['status'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat profil');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<List<TagihanModel>> fetchTagihan() async {
    try {
      final response = await _api.client.get(AppConstants.tagihanEndpoint);
      if (response.data['status'] == true) {
        final list = response.data['data'] as List;
        return list.map((item) => TagihanModel.fromJson(item)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat tagihan');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadBuktiBayar({
    required String idTagihan,
    required String metode,
    required String namaPengirim,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'id_tagihan': idTagihan,
        'metode_pembayaran': metode,
        'nama_pengirim': namaPengirim,
        'bukti': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _api.client.post(
        AppConstants.bayarEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['status'] == true) {
        return response.data;
      } else {
        throw Exception(
            response.data['message'] ?? 'Gagal mengunggah bukti bayar');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<List<PembayaranModel>> fetchRiwayat() async {
    try {
      final response = await _api.client.get(AppConstants.riwayatEndpoint);
      if (response.data['status'] == true) {
        final list = response.data['data'] as List;
        return list.map((item) => PembayaranModel.fromJson(item)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat riwayat');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMidtransSnap(String idTagihan) async {
    try {
      final response = await _api.client.post(
        AppConstants.midtransSnapEndpoint,
        data: {'id_tagihan': idTagihan},
      );
      if (response.data['status'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Gagal membuat sesi pembayaran Midtrans');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkMidtransStatus(String orderId) async {
    try {
      final response = await _api.client.get(
        '${AppConstants.midtransStatusEndpoint}/$orderId',
      );
      if (response.data['status'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Gagal memeriksa status pembayaran');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final resData = e.response?.data;
      if (resData is Map && resData.containsKey('message')) {
        throw Exception(resData['message']);
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw Exception(
          'Tidak dapat terhubung ke server SPP (${AppConstants.baseUrl}). Pastikan koneksi aktif.');
    }
    throw Exception('Kesalahan jaringan: ${e.message}');
  }
}
