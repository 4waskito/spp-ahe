import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../auth/login_screen.dart';
import '../admin/month_year_picker_dialog.dart';
import 'owner_report_viewer_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final AdminService _adminService = AdminService();

  // Filter state
  late String _selectedPeriode; // e.g. "Oktober 2026" or "Semua"
  String _statusFilter = 'semua'; // 'semua', 'sukses', 'pending', 'gagal'
  bool _isExporting = false;

  final List<String> _kNamaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriode = '${_kNamaBulan[now.month - 1]} ${now.year}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    admin.loadDashboard();
    admin.loadPembayaran();
  }

  void _stepMonth(int step) {
    if (_selectedPeriode == 'Semua') {
      final now = DateTime.now();
      setState(() {
        _selectedPeriode = '${_kNamaBulan[now.month - 1]} ${now.year}';
      });
      return;
    }

    final parts = _selectedPeriode.split(' ');
    if (parts.length >= 2) {
      final mIdx = _kNamaBulan.indexWhere(
          (m) => m.toLowerCase() == parts[0].toLowerCase());
      int y = int.tryParse(parts[1]) ?? DateTime.now().year;

      if (mIdx != -1) {
        int newMIdx = mIdx + step;
        if (newMIdx < 0) {
          newMIdx = 11;
          y--;
        } else if (newMIdx > 11) {
          newMIdx = 0;
          y++;
        }
        setState(() {
          _selectedPeriode = '${_kNamaBulan[newMIdx]} $y';
        });
      }
    }
  }

  Future<void> _pickPeriodeDialog() async {
    final picked = await showMonthYearPickerDialog(
      context,
      initialPeriode: _selectedPeriode == 'Semua' ? null : _selectedPeriode,
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _selectedPeriode = picked;
      });
    }
  }

  void _showExportModal(
      BuildContext context, double totalSukses, int countSukses) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final currencyFormat = NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        String exportScope = 'bulanan'; // 'bulanan' or 'tahunan'

        return StatefulBuilder(
          builder: (context, setModalState) {
            final activePeriodeLabel = exportScope == 'bulanan'
                ? (_selectedPeriode == 'Semua' ? 'Bulan Berjalan' : _selectedPeriode)
                : 'Tahunan (Semua Periode)';
            final targetPeriodeParam =
                exportScope == 'bulanan' ? _selectedPeriode : 'Semua';

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.download_rounded,
                            color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unduh Laporan Keuangan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Pilih cakupan Laporan Bulanan atau Tahunan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Pilihan Cakupan: Laporan Bulanan vs Laporan Tahunan
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setModalState(() => exportScope = 'bulanan'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: exportScope == 'bulanan'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: exportScope == 'bulanan'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Laporan Bulanan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: exportScope == 'bulanan'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: exportScope == 'bulanan'
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setModalState(() => exportScope = 'tahunan'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: exportScope == 'tahunan'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: exportScope == 'tahunan'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Laporan Tahunan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: exportScope == 'tahunan'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: exportScope == 'tahunan'
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exportScope == 'bulanan'
                                  ? 'PERIODE BULANAN'
                                  : 'PERIODE TAHUNAN',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activePeriodeLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (exportScope == 'bulanan')
                          Text(
                            currencyFormat.format(totalSukses),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          )
                        else
                          Text(
                            currencyFormat.format(admin.totalPendapatan),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pilih Format Dokumen:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: PDF Document
                  _ExportOptionTile(
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEE2E2),
                    title: 'Dokumen PDF (Siap Cetak / Simpan)',
                    subtitle:
                        'Format resmi dengan Kop Lembaga, rekapitulasi & lembar tanda tangan.',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openPdfViewer(targetPeriode: targetPeriodeParam);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Excel Spreadsheet
                  _ExportOptionTile(
                    icon: Icons.table_chart_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    title: 'Excel Spreadsheet (.xlsx)',
                    subtitle:
                        'Tabel data lengkap siap dibuka di Microsoft Excel / Google Sheets.',
                    onTap: () {
                      Navigator.pop(ctx);
                      _downloadExcel(targetPeriode: targetPeriodeParam);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Copy Text Summary
                  _ExportOptionTile(
                    icon: Icons.copy_all_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFDBEAFE),
                    title: 'Salin Rekapitulasi Teks / WhatsApp',
                    subtitle:
                        'Salin ringkasan ke clipboard untuk dikirim langsung via chat.',
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyTextSummary(totalSukses, countSukses);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openPdfViewer({String? targetPeriode}) {
    final peri = targetPeriode ?? _selectedPeriode;
    final url = _adminService.getReportViewUrl(periode: peri);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerReportViewerScreen(
          url: url,
          periode: peri,
        ),
      ),
    );
  }

  Future<void> _downloadExcel({String? targetPeriode}) async {
    if (_isExporting) return;
    final peri = targetPeriode ?? _selectedPeriode;
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Menyiapkan file Excel...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final res = await _adminService.exportExcel(periode: peri);
      final filename = res['filename']?.toString() ?? 'Laporan_SPP.xlsx';
      final downloadUrl = _adminService.resolveExportDownloadUrl(filename);

      if (!mounted) return;
      setState(() => _isExporting = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 26),
              SizedBox(width: 10),
              Text('File Excel Siap!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File berhasil dibuat di server untuk periode $_selectedPeriode.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filename,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tautan unduhan dapat dibuka langsung di browser atau disalin:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: downloadUrl));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tautan download Excel disalin ke clipboard!')),
                );
              },
              child: const Text('Salin Tautan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerReportViewerScreen(
                      url: downloadUrl,
                      periode: _selectedPeriode,
                    ),
                  ),
                );
              },
              child: const Text('Buka Download'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _copyTextSummary(double totalSukses, int countSukses) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final text = '''
*LAPORAN KEUANGAN SPP LES AHE*
Periode: $_selectedPeriode
Tanggal Cetak: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}
----------------------------------------
• Total Transaksi Sukses : $countSukses transaksi
• Total Pendapatan Lunas : ${currencyFormat.format(totalSukses)}
• Status Otorisasi      : Diverifikasi oleh Owner
----------------------------------------
_Dihasilkan secara otomatis melalui Sistem Mobile SPP Les Ahe_
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rekapitulasi keuangan disalin ke clipboard!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel owner?'),
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
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Get all payments from backend
    final allPembayaran = admin.pembayaranList;

    // Filter by selected period
    final periodFiltered = allPembayaran.where((p) {
      if (_selectedPeriode == 'Semua') return true;
      final periode = p['periode']?.toString().toLowerCase().trim() ?? '';
      return periode == _selectedPeriode.toLowerCase().trim();
    }).toList();

    // Calculate metrics for selected period
    final suksesPayments = periodFiltered.where((p) {
      final st = p['status_transaksi']?.toString().toLowerCase().trim() ?? '';
      return st == 'sukses';
    }).toList();

    final pendingPayments = periodFiltered.where((p) {
      final st = p['status_transaksi']?.toString().toLowerCase().trim() ?? '';
      return st == 'pending';
    }).toList();

    final gagalPayments = periodFiltered.where((p) {
      final st = p['status_transaksi']?.toString().toLowerCase().trim() ?? '';
      return st == 'gagal';
    }).toList();

    double totalSukses = 0;
    for (final p in suksesPayments) {
      totalSukses += double.tryParse(p['nominal']?.toString() ?? '0') ?? 0;
    }

    double totalPending = 0;
    for (final p in pendingPayments) {
      totalPending += double.tryParse(p['nominal']?.toString() ?? '0') ?? 0;
    }

    // Filter by status tab for the list
    final displayList = periodFiltered.where((p) {
      if (_statusFilter == 'semua') return true;
      final st = p['status_transaksi']?.toString().toLowerCase().trim() ?? '';
      return st == _statusFilter;
    }).toList();

    // Check available periods in DB for quick chips
    final availablePeriods = <String>{};
    for (final p in allPembayaran) {
      final per = p['periode']?.toString().trim();
      if (per != null && per.isNotEmpty) {
        availablePeriods.add(per);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: Color(0xFFF59E0B), size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner Financial Suite',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Portal Eksekutif Les Ahe',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171)),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 11, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedPeriode,
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Halo, ${user?.username ?? 'Owner'}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TOTAL PENDAPATAN TERVERIFIKASI',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(totalSukses),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✓ ${suksesPayments.length} Lunas',
                            style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⏳ ${pendingPayments.length} Pending',
                            style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 14),

                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _showExportModal(
                                context, totalSukses, suksesPayments.length),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              'Unduh Laporan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF475569)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openPdfViewer,
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 16, color: Color(0xFFF87171)),
                          label: const Text(
                            'Cetak PDF',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Filter Bar: Month Selector & Quick Navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Periode Bulan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (_selectedPeriode != 'Semua')
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() => _selectedPeriode = 'Semua');
                      },
                      child: const Text('Reset ke Semua',
                          style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Month Navigator Stepper
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Bulan Sebelumnya',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _stepMonth(-1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _pickPeriodeDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 16, color: Color(0xFF0F172A)),
                              const SizedBox(width: 8),
                              Text(
                                _selectedPeriode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF64748B), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bulan Berikutnya',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => _stepMonth(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Period Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip('Semua'),
                    const SizedBox(width: 6),
                    _buildPeriodChip(
                        '${_kNamaBulan[DateTime.now().month - 1]} ${DateTime.now().year}'),
                    const SizedBox(width: 6),
                    ...availablePeriods.map((per) {
                      if (per.toLowerCase() ==
                          '${_kNamaBulan[DateTime.now().month - 1]} ${DateTime.now().year}'
                              .toLowerCase()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildPeriodChip(per),
                      );
                    }),
                    ActionChip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      avatar: const Icon(Icons.edit_calendar_rounded,
                          size: 14, color: Color(0xFF0F172A)),
                      label: const Text('Pilih Lain...',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      onPressed: _pickPeriodeDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Empty Month Notification if zero transactions in chosen period
              if (periodFiltered.isEmpty && !admin.isLoadingPembayaran) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum ada transaksi di periode $_selectedPeriode.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Gunakan tombol di atas untuk beralih ke periode yang memiliki data (misal: Mei 2026 atau Semua Periode).',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Metric Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Lunas / Sukses',
                      value: currencyFormat.format(totalSukses),
                      countText: '${suksesPayments.length} transaksi',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      title: 'Pending Verifikasi',
                      value: currencyFormat.format(totalPending),
                      countText: '${pendingPayments.length} menunggu',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SmallMetricCard(
                      title: 'Total Transaksi',
                      value: '${periodFiltered.length}',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallMetricCard(
                      title: 'Total Siswa Aktif',
                      value: '${admin.totalSiswa}',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallMetricCard(
                      title: 'Tagihan Belum Lunas',
                      value: '${admin.tagihanBelumLunas}',
                      icon: Icons.assignment_late_outlined,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Payment Records Header & Status Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Transaksi (${displayList.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Unduh Excel',
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_view_rounded,
                            color: Color(0xFF059669)),
                    onPressed: _isExporting ? null : _downloadExcel,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('Semua Status', 'semua'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Sukses (${suksesPayments.length})', 'sukses'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Pending (${pendingPayments.length})', 'pending'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Gagal (${gagalPayments.length})', 'gagal'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Payment List
              if (admin.isLoadingPembayaran) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (displayList.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada transaksi pada filter ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Periode: $_selectedPeriode • Status: $_statusFilter',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final p = displayList[idx];
                    return _buildPaymentCard(p, currencyFormat);
                  },
                ),
              ],

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected =
        _selectedPeriode.toLowerCase().trim() == label.toLowerCase().trim();
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0F172A),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (_) {
        setState(() {
          _selectedPeriode = label;
        });
      },
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF334155),
      side: BorderSide(
        color: isSelected ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) {
        setState(() => _statusFilter = value);
      },
    );
  }

  Widget _buildPaymentCard(
      Map<String, dynamic> p, NumberFormat currencyFormat) {
    final nama = p['nama_murid']?.toString() ?? '-';
    final nis = p['nis']?.toString() ?? '-';
    final periode = p['periode']?.toString() ?? '-';
    final nominal = double.tryParse(p['nominal']?.toString() ?? '0') ?? 0;
    final metode = p['metode_bayar']?.toString() ?? '-';
    final waktu = p['waktu_bayar']?.toString() ?? '-';
    final status = p['status_transaksi']?.toString().toLowerCase() ?? '';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (status == 'sukses') {
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFECFDF5);
      statusLabel = 'Sukses';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'Pending';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEF2F2);
      statusLabel = 'Gagal';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          size: 20, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'NIS: $nis',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode: $periode',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$metode • $waktu',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Text(
                currencyFormat.format(nominal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String countText;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.countText,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            countText,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
