import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/tagihan_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';
import '../../payment/pay_bill_screen.dart';

class BillCard extends StatelessWidget {
  final TagihanModel tagihan;
  final VoidCallback? onPaymentSuccess;

  const BillCard({
    super.key,
    required this.tagihan,
    this.onPaymentSuccess,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (tagihan.isLunas) {
      statusColor = AppTheme.success;
      statusBg = AppTheme.success.withValues(alpha: 0.12);
      statusLabel = 'Lunas';
      statusIcon = Icons.check_circle_rounded;
    } else if (tagihan.isPending) {
      statusColor = AppTheme.warning;
      statusBg = AppTheme.warning.withValues(alpha: 0.12);
      statusLabel = 'Menunggu Verifikasi';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = AppTheme.danger;
      statusBg = AppTheme.danger.withValues(alpha: 0.12);
      statusLabel = 'Belum Lunas';
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tagihan.isBelumLunas
              ? AppTheme.danger.withValues(alpha: 0.2)
              : AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tagihan.periode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          tagihan.idTagihan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nominal Tagihan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(tagihan.nominal),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (tagihan.jatuhTempo.isNotEmpty &&
                        tagihan.jatuhTempo != '0000-00-00') ...[
                      const SizedBox(height: 2),
                      Text(
                        'Jatuh tempo: ${DateFormatter.formatDate(tagihan.jatuhTempo)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (tagihan.isBelumLunas)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayBillScreen(tagihan: tagihan),
                        ),
                      );
                      if (result == true) {
                        onPaymentSuccess?.call();
                      }
                    },
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text(
                      'Bayar',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else if (tagihan.isPending)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      side: const BorderSide(color: AppTheme.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: null,
                    icon: const Icon(Icons.sync_rounded,
                        size: 14, color: AppTheme.warning),
                    label: const Text(
                      'Diverifikasi',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        'Terbayar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
