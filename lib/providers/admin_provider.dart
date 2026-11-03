import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = false;
  String? _dashboardError;

  List<Map<String, dynamic>> _pembayaranList = [];
  bool _isLoadingPembayaran = false;
  String? _pembayaranError;

  List<Map<String, dynamic>> _tagihanList = [];
  bool _isLoadingTagihan = false;
  String? _tagihanError;

  List<Map<String, dynamic>> _siswaList = [];
  bool _isLoadingSiswa = false;
  String? _siswaError;

  List<Map<String, dynamic>> _paketList = [];
  bool _isLoadingPaket = false;

  bool _isProcessing = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;

  List<Map<String, dynamic>> get pembayaranList => _pembayaranList;
  bool get isLoadingPembayaran => _isLoadingPembayaran;
  String? get pembayaranError => _pembayaranError;

  List<Map<String, dynamic>> get tagihanList => _tagihanList;
  bool get isLoadingTagihan => _isLoadingTagihan;
  String? get tagihanError => _tagihanError;

  List<Map<String, dynamic>> get siswaList => _siswaList;
  bool get isLoadingSiswa => _isLoadingSiswa;
  String? get siswaError => _siswaError;

  List<Map<String, dynamic>> get paketList => _paketList;
  bool get isLoadingPaket => _isLoadingPaket;

  bool get isProcessing => _isProcessing;

  int get totalSiswa =>
      int.tryParse(_dashboardData?['total_siswa']?.toString() ?? '0') ?? 0;
  double get totalPendapatan =>
      double.tryParse(_dashboardData?['total_pendapatan']?.toString() ?? '0') ?? 0.0;
  int get pendingVerifikasi =>
      int.tryParse(_dashboardData?['pending_verifikasi']?.toString() ?? '0') ?? 0;
  int get tagihanBelumLunas =>
      int.tryParse(_dashboardData?['tagihan_belum_lunas']?.toString() ?? '0') ?? 0;

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true; _dashboardError = null; notifyListeners();
    try { _dashboardData = await _adminService.getDashboard(); }
    catch (e) { _dashboardError = e.toString().replaceFirst('Exception: ', ''); }
    _isLoadingDashboard = false; notifyListeners();
  }

  Future<void> loadPembayaran() async {
    _isLoadingPembayaran = true; _pembayaranError = null; notifyListeners();
    try { _pembayaranList = await _adminService.getPembayaran(); }
    catch (e) { _pembayaranError = e.toString().replaceFirst('Exception: ', ''); }
    _isLoadingPembayaran = false; notifyListeners();
  }

  Future<void> loadTagihan() async {
    _isLoadingTagihan = true; _tagihanError = null; notifyListeners();
    try { _tagihanList = await _adminService.getTagihan(); }
    catch (e) { _tagihanError = e.toString().replaceFirst('Exception: ', ''); }
    _isLoadingTagihan = false; notifyListeners();
  }

  Future<String> generateTagihan(String periode, String jatuhTempo) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.generateTagihan(periode, jatuhTempo);
      await Future.wait([loadDashboard(), loadTagihan()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<String> deleteTagihan(String id) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.deleteTagihan(id);
      await Future.wait([loadDashboard(), loadTagihan()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<void> loadSiswa() async {
    _isLoadingSiswa = true; _siswaError = null; notifyListeners();
    try { _siswaList = await _adminService.getSiswa(); }
    catch (e) { _siswaError = e.toString().replaceFirst('Exception: ', ''); }
    _isLoadingSiswa = false; notifyListeners();
  }

  Future<void> loadPaket() async {
    _isLoadingPaket = true; notifyListeners();
    try { _paketList = await _adminService.getPaket(); }
    catch (_) {}
    _isLoadingPaket = false; notifyListeners();
  }

  Future<String> createSiswa(Map<String, dynamic> payload) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.createSiswa(payload);
      await Future.wait([loadDashboard(), loadSiswa()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<String> updateSiswa(String nis, Map<String, dynamic> payload) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.updateSiswa(nis, payload);
      await loadSiswa();
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<String> deleteSiswa(String nis) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.deleteSiswa(nis);
      await Future.wait([loadDashboard(), loadSiswa(), loadTagihan()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<String> approvePembayaran(String id) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.approvePembayaran(id);
      await Future.wait([loadDashboard(), loadPembayaran()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  Future<String> rejectPembayaran(String id) async {
    _isProcessing = true; notifyListeners();
    try {
      final msg = await _adminService.rejectPembayaran(id);
      await Future.wait([loadDashboard(), loadPembayaran()]);
      _isProcessing = false; notifyListeners(); return msg;
    } catch (e) { _isProcessing = false; notifyListeners(); rethrow; }
  }

  void reset() {
    _dashboardData = null; _pembayaranList = []; _tagihanList = []; _siswaList = [];
    _dashboardError = null; _pembayaranError = null; _tagihanError = null; _siswaError = null;
    _isLoadingDashboard = false; _isLoadingPembayaran = false;
    _isLoadingTagihan = false; _isLoadingSiswa = false; _isProcessing = false;
    notifyListeners();
  }
}
