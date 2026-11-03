import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';
import 'month_year_picker_dialog.dart';

class AdminTagihanScreen extends StatefulWidget {
  const AdminTagihanScreen({super.key});
  @override
  State<AdminTagihanScreen> createState() => _AdminTagihanScreenState();
}

class _AdminTagihanScreenState extends State<AdminTagihanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadTagihan();
    });
  }

  Future<void> _showGenerateDialog() async {
    final now = DateTime.now();
    final bulanIni = '${kNamaBulan[now.month - 1]} ${now.year}';
    final nextMonthDate = DateTime(now.year, now.month + 1, 1);
    final bulanDepan =
        '${kNamaBulan[nextMonthDate.month - 1]} ${nextMonthDate.year}';

    final periodeCtrl = TextEditingController(text: bulanIni);
    final jatuhTempoCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd')
          .format(DateTime(now.year, now.month, 10)),
    );
    final formKey = GlobalKey<FormState>();

    void setPeriode(String periode) {
      periodeCtrl.text = periode;
      final parts = periode.trim().split(' ');
      if (parts.length >= 2) {
        final mIdx = kNamaBulan.indexWhere(
            (m) => m.toLowerCase() == parts[0].toLowerCase());
        final y = int.tryParse(parts[1]);
        if (mIdx != -1 && y != null) {
          jatuhTempoCtrl.text =
              DateFormat('yyyy-MM-dd').format(DateTime(y, mIdx + 1, 10));
        }
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.post_add_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Buat Tagihan SPP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih periode untuk generate tagihan SPP seluruh siswa secara otomatis.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Chips
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(
                              color: periodeCtrl.text == bulanIni
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: periodeCtrl.text == bulanIni ? 1.5 : 1,
                            ),
                            backgroundColor: periodeCtrl.text == bulanIni
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              setPeriode(bulanIni);
                            });
                          },
                          child: Text(
                            'Bulan Ini\n$bulanIni',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: periodeCtrl.text == bulanIni
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: periodeCtrl.text == bulanIni
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(
                              color: periodeCtrl.text == bulanDepan
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: periodeCtrl.text == bulanDepan ? 1.5 : 1,
                            ),
                            backgroundColor: periodeCtrl.text == bulanDepan
                                ? AppTheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              setPeriode(bulanDepan);
                            });
                          },
                          child: Text(
                            'Bulan Depan\n$bulanDepan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: periodeCtrl.text == bulanDepan
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: periodeCtrl.text == bulanDepan
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Selectable Periode
                  TextFormField(
                    controller: periodeCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Periode',
                      hintText: 'Ketuk untuk pilih bulan & tahun',
                      prefixIcon: const Icon(Icons.calendar_month_rounded,
                          color: AppTheme.primary),
                      suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
                          size: 32, color: AppTheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showMonthYearPickerDialog(
                        dialogCtx,
                        initialPeriode: periodeCtrl.text,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          setPeriode(picked);
                        });
                      }
                    },
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Periode wajib dipilih'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Jatuh Tempo
                  TextFormField(
                    controller: jatuhTempoCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Jatuh Tempo',
                      hintText: 'Pilih tanggal',
                      prefixIcon: const Icon(Icons.event_rounded),
                      suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
                          size: 32),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final currentDt =
                          DateTime.tryParse(jatuhTempoCtrl.text) ??
                              DateTime.now();
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: currentDt,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          jatuhTempoCtrl.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Jatuh tempo wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Buat Tagihan'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final admin = Provider.of<AdminProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final msg = await admin.generateTagihan(
                  periodeCtrl.text.trim(),
                  jatuhTempoCtrl.text.trim(),
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

  Future<void> _confirmDelete(BuildContext ctx, String id, String periode, String nama) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tagihan?'),
        content: Text('Hapus tagihan $periode milik $nama?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final msg = await admin.deleteTagihan(id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas': return AppTheme.success;
      case 'pending': return AppTheme.warning;
      default: return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Buat Tagihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => admin.loadTagihan(),
        child: admin.isLoadingTagihan
            ? const Center(child: CircularProgressIndicator())
            : admin.tagihanError != null
                ? _buildError(admin.tagihanError!, () => admin.loadTagihan())
                : admin.tagihanList.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: admin.tagihanList.length,
                        itemBuilder: (ctx, i) {
                          final t = admin.tagihanList[i];
                          final status = t['status_bayar']?.toString() ?? '';
                          final nominal = double.tryParse(t['nominal']?.toString() ?? '0') ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  status.toLowerCase() == 'lunas'
                                      ? Icons.check_circle_rounded
                                      : Icons.receipt_long_rounded,
                                  color: _statusColor(status),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                t['nama_murid']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${t['periode'] ?? '-'} • Jatuh: ${t['jatuh_tempo'] ?? '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(nominal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(
                                      context,
                                      t['id_tagihan']?.toString() ?? '',
                                      t['periode']?.toString() ?? '',
                                      t['nama_murid']?.toString() ?? '',
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.danger,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Belum ada tagihan.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap tombol Generate untuk membuat tagihan baru.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      );

  Widget _buildError(String error, VoidCallback retry) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.danger)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: retry, child: const Text('Coba Lagi')),
          ],
        ),
      );
}
