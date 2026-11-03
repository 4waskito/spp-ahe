import 'package:flutter/material.dart';
import '../models/tagihan_model.dart';
import '../models/pembayaran_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  List<TagihanModel> _tagihans = [];
  List<PembayaranModel> _riwayats = [];
  Map<String, dynamic>? _profileStats;

  bool _isLoadingDashboard = false;
  bool _isLoadingRiwayat = false;
  bool _isUploading = false;
  bool _isCreatingSnap = false;
  bool _isCheckingStatus = false;
  String? _errorMessage;

  List<TagihanModel> get tagihans => _tagihans;
  List<PembayaranModel> get riwayats => _riwayats;
  Map<String, dynamic>? get profileStats => _profileStats;

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingRiwayat => _isLoadingRiwayat;
  bool get isUploading => _isUploading;
  bool get isCreatingSnap => _isCreatingSnap;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get errorMessage => _errorMessage;

  List<TagihanModel> get unpaidBills =>
      _tagihans.where((t) => t.isBelumLunas || t.isPending).toList();

  List<TagihanModel> get paidBills =>
      _tagihans.where((t) => t.isLunas).toList();

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchProfile(),
        _service.fetchTagihan(),
      ]);

      _profileStats = results[0] as Map<String, dynamic>;
      _tagihans = results[1] as List<TagihanModel>;
      _isLoadingDashboard = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDashboard = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadRiwayat() async {
    _isLoadingRiwayat = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _riwayats = await _service.fetchRiwayat();
      _isLoadingRiwayat = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRiwayat = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> submitPayment({
    required String idTagihan,
    required String metode,
    required String namaPengirim,
    required String filePath,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.uploadBuktiBayar(
        idTagihan: idTagihan,
        metode: metode,
        namaPengirim: namaPengirim,
        filePath: filePath,
      );

      _isUploading = false;
      notifyListeners();

      // Refresh dashboard & riwayat in background
      loadDashboard();
      loadRiwayat();
      return true;
    } catch (e) {
      _isUploading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> createMidtransPayment(String idTagihan) async {
    _isCreatingSnap = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.createMidtransSnap(idTagihan);
      _isCreatingSnap = false;
      notifyListeners();
      return data;
    } catch (e) {
      _isCreatingSnap = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkMidtransStatus(String orderId) async {
    _isCheckingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.checkMidtransStatus(orderId);
      _isCheckingStatus = false;
      notifyListeners();

      if (data['status_transaksi'] == 'sukses' || data['status_bayar'] == 'lunas') {
        loadDashboard();
        loadRiwayat();
      }
      return data;
    } catch (e) {
      _isCheckingStatus = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
