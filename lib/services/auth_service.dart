import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Unified login — backend determines role from credentials.
  /// Endpoint: POST /api/auth/login_unified
  /// Body: { "username": "...", "password": "..." }
  /// Response: { status, token, data: { role: "siswa"|"admin"|"owner", ... } }
  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _api.client.post(
        '${AppConstants.baseUrl}/auth/login_unified',
        data: {
          'username': username.trim(),
          'password': password.trim(),
        },
      );

      final data = response.data;
      if (data['status'] == true) {
        final token = data['token'] as String;
        final userData = UserModel.fromJson(data['data']);

        // Save token to secure storage
        await _api.storage.write(key: AppConstants.keyToken, value: token);

        // Save user profile to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUser, jsonEncode(userData.toJson()));

        return userData;
      } else {
        throw Exception(data['message'] ?? 'Login gagal.');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map) {
          if (resData.containsKey('message')) {
            throw Exception(resData['message']);
          } else if (resData.containsKey('messages') && resData['messages'] is Map && resData['messages'].containsKey('message')) {
            throw Exception(resData['messages']['message']);
          }
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Tidak dapat terhubung ke server SPP (${AppConstants.baseUrl}). Pastikan server aktif dan alamat IP benar.');
      }
      throw Exception('Gagal melakukan login: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await _api.client.post('${AppConstants.baseUrl}/auth/logout');
    } catch (_) {}

    await _api.storage.delete(key: AppConstants.keyToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUser);
  }

  Future<String?> getToken() async {
    return await _api.storage.read(key: AppConstants.keyToken);
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.keyUser);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr);
        return UserModel.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
