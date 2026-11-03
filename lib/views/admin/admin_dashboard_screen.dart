import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../auth/login_screen.dart';
import 'admin_pembayaran_screen.dart';
import 'admin_tagihan_screen.dart';
import 'admin_siswa_screen.dart';
import 'month_year_picker_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    admin.loadDashboard();
    admin.loadPembayaran();
    admin.loadTagihan();
    admin.loadSiswa();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    final admin = Provider.of<AdminProvider>(context, listen: false);
    if (index == 1) {
      admin.loadTagihan();
    } else if (index == 2) {
      admin.loadSiswa();
    } else if (index == 3) {
      admin.loadPembayaran();
    }
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
                    'Pilih periode untuk generate tagihan SPP seluruh siswa aktif secara otomatis.',
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

                  // Tanggal Jatuh Tempo
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Buat Tagihan'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final admin =
                    Provider.of<AdminProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final msg = await admin.generateTagihan(
                    periodeCtrl.text.trim(),
                    jatuhTempoCtrl.text.trim(),
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: AppTheme.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final adminProv =
                  Provider.of<AdminProvider>(context, listen: false);
              adminProv.reset();
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTabContent(
            onGenerateTagihan: _showGenerateDialog,
            onGoToTagihan: () => _onTabTapped(1),
            onGoToSiswa: () => _onTabTapped(2),
            onGoToPembayaran: () => _onTabTapped(3),
          ),
          const AdminTagihanScreen(),
          const AdminSiswaScreen(),
          const AdminPembayaranScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Tagihan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Siswa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments_rounded),
                label: 'Pembayaran',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTabContent extends StatelessWidget {
  final VoidCallback onGenerateTagihan;
  final VoidCallback onGoToTagihan;
  final VoidCallback onGoToSiswa;
  final VoidCallback onGoToPembayaran;

  const _DashboardTabContent({
    required this.onGenerateTagihan,
    required this.onGoToTagihan,
    required this.onGoToSiswa,
    required this.onGoToPembayaran,
  });

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: () async {
        admin.loadDashboard();
        admin.loadPembayaran();
        admin.loadTagihan();
        admin.loadSiswa();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.username ?? 'Admin'}!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panel Administrasi & Tagihan SPP',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat Cards Grid
            if (admin.isLoadingDashboard) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (admin.dashboardError != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 40, color: AppTheme.danger),
                      const SizedBox(height: 8),
                      Text(admin.dashboardError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Siswa',
                      value: admin.totalSiswa.toString(),
                      icon: Icons.people_outline_rounded,
                      color: AppTheme.primary,
                      bgColor: AppTheme.primary.withValues(alpha: 0.1),
                      onTap: onGoToSiswa,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Sudah Bayar',
                      value: admin.pembayaranList
                          .where((p) =>
                              (p['status_transaksi']?.toString().toLowerCase() ??
                                  '') ==
                              'sukses')
                          .length
                          .toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                      bgColor: AppTheme.success.withValues(alpha: 0.1),
                      onTap: onGoToPembayaran,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Belum Bayar',
                      value: admin.tagihanBelumLunas.toString(),
                      icon: Icons.assignment_late_outlined,
                      color: AppTheme.danger,
                      bgColor: AppTheme.danger.withValues(alpha: 0.1),
                      onTap: onGoToTagihan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Menunggu Proses',
                      value: admin.pendingVerifikasi.toString(),
                      icon: Icons.hourglass_top_rounded,
                      color: AppTheme.warning,
                      bgColor: AppTheme.warning.withValues(alpha: 0.1),
                      onTap: onGoToPembayaran,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Banner: Buat Tagihan SPP Bulanan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.post_add_rounded,
                        color: AppTheme.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Buat Tagihan SPP',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generate tagihan bulanan seluruh siswa',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onGenerateTagihan,
                    child: const Text('Buat',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Quick Actions Section (Aksi Cepat - Web Parity)
            const Text(
              'Aksi Cepat & Menu Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.post_add_rounded,
                    title: 'Buat Tagihan',
                    subtitle: 'Generate tagihan baru',
                    color: AppTheme.primary,
                    bgColor: AppTheme.primary.withValues(alpha: 0.1),
                    onTap: onGenerateTagihan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Kelola Tagihan',
                    subtitle: '${admin.tagihanBelumLunas} belum lunas',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    onTap: onGoToTagihan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Data Siswa',
                    subtitle: '${admin.totalSiswa} murid terdaftar',
                    color: AppTheme.secondary,
                    bgColor: AppTheme.secondary.withValues(alpha: 0.1),
                    onTap: onGoToSiswa,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Verifikasi Bayar',
                    subtitle: '${admin.pendingVerifikasi} menunggu',
                    color: AppTheme.warning,
                    bgColor: AppTheme.warning.withValues(alpha: 0.1),
                    onTap: onGoToPembayaran,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section: Pembayaran Pending
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pembayaran Pending',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onGoToPembayaran,
                  child: const Text('Lihat Semua →',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _PendingList(admin: admin),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color, bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final AdminProvider admin;

  const _PendingList({required this.admin});

  @override
  Widget build(BuildContext context) {
    if (admin.isLoadingPembayaran) {
      return const Center(child: CircularProgressIndicator());
    }
    final pendingPayments = admin.pembayaranList
        .where((p) =>
            (p['status_transaksi']?.toString().toLowerCase() ?? '') ==
            'pending')
        .take(5)
        .toList();

    if (pendingPayments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 38, color: AppTheme.success.withValues(alpha: 0.6)),
            const SizedBox(height: 6),
            const Text('Tidak ada pembayaran pending',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingPayments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final p = pendingPayments[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nama_murid']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${p['periode'] ?? '-'} • ${p['metode_bayar'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
