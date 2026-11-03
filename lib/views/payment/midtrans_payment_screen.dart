import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/tagihan_model.dart';
import '../../providers/payment_provider.dart';
import '../../utils/currency_formatter.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String redirectUrl;
  final String orderId;
  final TagihanModel tagihan;

  const MidtransPaymentScreen({
    super.key,
    required this.redirectUrl,
    required this.orderId,
    required this.tagihan,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late final WebViewController _webViewController;
  int _loadingProgress = 0;
  bool _isLoading = true;
  Timer? _pollingTimer;
  bool _isPaymentSettled = false;
  bool _isCheckingNow = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startAutoPolling();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkUrlForCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept finish / callback url if configured
            if (_checkUrlForCompletion(request.url)) {
              return NavigationDecision.prevent;
            }
            // Allow standard web navigation
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            // Block unsupported custom deep links to avoid webview crash
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _startAutoPolling() {
    // Poll status silently every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isPaymentSettled) return;
      await _checkStatusSilently();
    });
  }

  Future<void> _checkStatusSilently() async {
    try {
      final payment = Provider.of<PaymentProvider>(context, listen: false);
      final statusData = await payment.checkMidtransStatus(widget.orderId);

      if (!mounted || _isPaymentSettled) return;

      if (statusData != null) {
        final statusBayar = statusData['status_bayar'] ?? '';
        final statusTransaksi = statusData['status_transaksi'] ?? '';

        if (statusBayar == 'lunas' || statusTransaksi == 'sukses') {
          _triggerSuccess();
        }
      }
    } catch (_) {
      // Ignore background polling errors
    }
  }

  bool _checkUrlForCompletion(String url) {
    final lower = url.toLowerCase();
    // Midtrans redirect keywords for finished payments
    if (lower.contains('#/success') ||
        lower.contains('status_code=200') ||
        lower.contains('transaction_status=settlement') ||
        lower.contains('finish')) {
      _checkStatusSilently();
      return true;
    }
    return false;
  }

  void _triggerSuccess() {
    if (_isPaymentSettled) return;
    _isPaymentSettled = true;
    _pollingTimer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pembayaran Terverifikasi Lunas!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Return true to parent screen
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _manualCheckStatus() async {
    if (_isCheckingNow) return;
    setState(() => _isCheckingNow = true);

    final payment = Provider.of<PaymentProvider>(context, listen: false);
    final statusData = await payment.checkMidtransStatus(widget.orderId);

    if (!mounted) return;
    setState(() => _isCheckingNow = false);

    if (statusData != null) {
      final statusBayar = statusData['status_bayar'] ?? '';
      final statusTransaksi = statusData['status_transaksi'] ?? '';

      if (statusBayar == 'lunas' || statusTransaksi == 'sukses') {
        _triggerSuccess();
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status saat ini: ${statusTransaksi.toUpperCase()} (Belum dibayar/menunggu verifikasi).'),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Pembayaran?'),
        content: const Text(
          'Sesi pembayaran ini tetap aktif. Anda dapat melanjutkan pembayaran atau mengecek statusnya di halaman tagihan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tetap di Sini'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCancelConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Tutup',
            onPressed: _showCancelConfirmation,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pembayaran Online',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Midtrans Snap • ${CurrencyFormatter.format(widget.tagihan.nominal)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Muat Ulang Halaman',
              onPressed: () => _webViewController.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    minHeight: 3,
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            // Top Auto-Validation Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Auto-verifikasi aktif: Status otomatis lunas begitu dibayar.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _isCheckingNow ? null : _manualCheckStatus,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        _isCheckingNow ? 'Memeriksa...' : 'Cek Status',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Embedded Midtrans Snap WebView
            Expanded(
              child: WebViewWidget(controller: _webViewController),
            ),

            // Bottom Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Order ID: ${widget.orderId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pilih metode di atas & selesaikan pembayaran',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Salin Order ID',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order ID disalin ke clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
