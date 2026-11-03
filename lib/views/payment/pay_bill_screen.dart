import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/tagihan_model.dart';
import '../../providers/payment_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import 'midtrans_payment_screen.dart';

class PayBillScreen extends StatefulWidget {
  final TagihanModel tagihan;

  const PayBillScreen({super.key, required this.tagihan});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  // Active Midtrans session data
  Map<String, dynamic>? _midtransSession;
  bool _isCheckingMidtrans = false;

  Future<void> _openMidtransPayment({
    required String redirectUrl,
    required String orderId,
  }) async {
    final isSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MidtransPaymentScreen(
          redirectUrl: redirectUrl,
          orderId: orderId,
          tagihan: widget.tagihan,
        ),
      ),
    );

    if (!mounted) return;

    if (isSuccess == true) {
      _showSuccessDialog(
        title: 'Pembayaran Berhasil!',
        desc:
            'Pembayaran SPP telah terverifikasi secara otomatis oleh sistem. Status tagihan Anda kini Lunas.',
      );
    } else {
      // Periksa status satu kali saat kembali dari halaman pembayaran
      _checkMidtransStatus(silent: true);
    }
  }

  void _handlePayWithMidtrans() async {
    final payment = Provider.of<PaymentProvider>(context, listen: false);
    final session =
        await payment.createMidtransPayment(widget.tagihan.idTagihan);

    if (!mounted) return;

    if (session != null) {
      setState(() {
        _midtransSession = session;
      });

      final redirectUrl = session['redirect_url'] as String? ?? '';
      final orderId = session['order_id'] as String? ?? '';

      if (redirectUrl.isNotEmpty) {
        _openMidtransPayment(redirectUrl: redirectUrl, orderId: orderId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment.errorMessage ??
              'Gagal membuat sesi pembayaran otomatis'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _checkMidtransStatus({bool silent = false}) async {
    if (_midtransSession == null) return;
    final orderId = _midtransSession!['order_id'] as String;

    if (!silent) {
      setState(() {
        _isCheckingMidtrans = true;
      });
    }

    final payment = Provider.of<PaymentProvider>(context, listen: false);
    final statusData = await payment.checkMidtransStatus(orderId);

    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isCheckingMidtrans = false;
      });
    }

    if (statusData != null) {
      final statusBayar = statusData['status_bayar'] ?? '';
      final statusTransaksi = statusData['status_transaksi'] ?? '';

      if (statusBayar == 'lunas' || statusTransaksi == 'sukses') {
        _showSuccessDialog(
          title: 'Pembayaran Berhasil!',
          desc:
              'Pembayaran telah terverifikasi secara otomatis oleh sistem. Tagihan Anda otomatis Lunas.',
        );
      } else if (!silent) {
        if (statusTransaksi == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Status: Menunggu Pembayaran. Silakan selesaikan transaksi di Virtual Account atau QRIS Anda.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status transaksi: $statusTransaksi'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment.errorMessage ?? 'Gagal memeriksa status'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _showSuccessDialog({required String title, required String desc}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Kembali ke Tagihan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = Provider.of<PaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran SPP Otomatis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bill Summary Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tagihan Bulan ${widget.tagihan.periode}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.tagihan.idTagihan,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(widget.tagihan.nominal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.tagihan.jatuhTempo.isNotEmpty &&
                      widget.tagihan.jatuhTempo != '0000-00-00')
                    Text(
                      'Batas Jatuh Tempo: ${DateFormatter.formatDate(widget.tagihan.jatuhTempo)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Automatic Payment Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembayaran Otomatis Real-time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem memverifikasi pembayaran secara otomatis detik itu juga. Orang tua siswa tidak perlu repot mengunggah foto struk transfer manual.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Midtrans Online Methods Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilihan Kanal Pembayaran Otomatis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih metode pembayaran favorit Anda di layar checkout Midtrans:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChannelBadge(
                          'BCA Virtual Account', Colors.blue.shade700),
                      _buildChannelBadge(
                          'Mandiri Bill', Colors.indigo.shade800),
                      _buildChannelBadge(
                          'BRI Virtual Account', Colors.blue.shade900),
                      _buildChannelBadge(
                          'BNI Virtual Account', Colors.teal.shade700),
                      _buildChannelBadge(
                          'Permata VA', Colors.green.shade800),
                      _buildChannelBadge(
                          'QRIS (GoPay/ShopeePay/Dana)', Colors.purple.shade700),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action: Start Payment or Check Status
            if (_midtransSession == null) ...[
              ElevatedButton.icon(
                onPressed: payment.isCreatingSnap ? null : _handlePayWithMidtrans,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: payment.isCreatingSnap
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.lock_outline_rounded, size: 20),
                label: Text(
                  payment.isCreatingSnap
                      ? 'Menyiapkan Jalur Pembayaran...'
                      : 'Bayar Otomatis Sekarang',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              // Active Session Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sesi Pembayaran Aktif',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'MENUNGGU BAYAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order ID: ${_midtransSession!['order_id'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final redirectUrl =
                                  _midtransSession!['redirect_url'] as String? ??
                                      '';
                              final orderId =
                                  _midtransSession!['order_id'] as String? ??
                                      '';
                              _openMidtransPayment(
                                  redirectUrl: redirectUrl, orderId: orderId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 16, color: Colors.white),
                            label: const Text(
                              'Lanjutkan Pembayaran',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCheckingMidtrans
                                ? null
                                : () => _checkMidtransStatus(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isCheckingMidtrans
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync_rounded,
                                    size: 16, color: AppTheme.primary),
                            label: const Text(
                              'Cek Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
