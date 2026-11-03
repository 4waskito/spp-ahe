import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminSiswaScreen extends StatefulWidget {
  const AdminSiswaScreen({super.key});

  @override
  State<AdminSiswaScreen> createState() => _AdminSiswaScreenState();
}

class _AdminSiswaScreenState extends State<AdminSiswaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'semua'; // 'semua', 'belum_lunas', 'lunas'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadSiswa();
      admin.loadPaket();
      admin.loadTagihan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFormDialog({Map<String, dynamic>? siswa}) {
    final isEdit = siswa != null;
    final admin = Provider.of<AdminProvider>(context, listen: false);

    final formKey = GlobalKey<FormState>();
    final nisController =
        TextEditingController(text: isEdit ? (siswa['nis'] ?? '') : '');
    final namaController =
        TextEditingController(text: isEdit ? (siswa['nama_murid'] ?? '') : '');
    final alamatController =
        TextEditingController(text: isEdit ? (siswa['alamat'] ?? '') : '');
    final tglLahirController =
        TextEditingController(text: isEdit ? (siswa['tanggal_lahir'] ?? '') : '');
    final passwordController = TextEditingController();

    String jenisKelamin = isEdit
        ? (siswa['jenis_kelamin'] ?? 'laki-laki')
        : 'laki-laki';
    String level = isEdit ? (siswa['level']?.toString() ?? '1') : '1';

    // Default package
    String selectedPaketId = isEdit
        ? (siswa['id_paket'] ?? (admin.paketList.isNotEmpty ? admin.paketList.first['id_paket'] : 'PKT001'))
        : (admin.paketList.isNotEmpty ? admin.paketList.first['id_paket'] : 'PKT001');

    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isEdit
                                      ? Icons.edit_rounded
                                      : Icons.person_add_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // NIS Field
                      TextFormField(
                        controller: nisController,
                        enabled: !isEdit,
                        decoration: InputDecoration(
                          labelText: 'Nomor Induk Siswa (NIS)*',
                          hintText: 'Contoh: NIS010',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: isEdit,
                          fillColor: isEdit ? Colors.grey.shade100 : Colors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'NIS wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nama Murid Field
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap Siswa*',
                          hintText: 'Contoh: Muhammad Rizky',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama murid wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Jenis Kelamin & Level in Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: jenisKelamin,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin*',
                                prefixIcon: Icon(Icons.wc_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'laki-laki',
                                  child: Text('Laki-laki'),
                                ),
                                DropdownMenuItem(
                                  value: 'perempuan',
                                  child: Text('Perempuan'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() => jenisKelamin = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: level,
                              decoration: const InputDecoration(
                                labelText: 'Level*',
                                prefixIcon: Icon(Icons.stairs_rounded),
                              ),
                              items: ['1', '2', '3', '4', '5']
                                  .map(
                                    (lvl) => DropdownMenuItem(
                                      value: lvl,
                                      child: Text('Level $lvl'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() => level = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Paket SPP Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: admin.paketList.any((p) => p['id_paket'] == selectedPaketId)
                            ? selectedPaketId
                            : (admin.paketList.isNotEmpty
                                ? admin.paketList.first['id_paket']
                                : null),
                        decoration: const InputDecoration(
                          labelText: 'Paket SPP Kursus*',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: admin.paketList.map((p) {
                          final nominal = double.tryParse(
                                  p['nominal']?.toString() ?? '0') ??
                              0;
                          final formatted = NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(nominal);
                          return DropdownMenuItem<String>(
                            value: p['id_paket']?.toString(),
                            child: Text(
                              '${p['nama_paket']} ($formatted)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedPaketId = v);
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Pilih salah satu paket SPP' : null,
                      ),
                      const SizedBox(height: 14),

                      // Tanggal Lahir (Date Picker)
                      TextFormField(
                        controller: tglLahirController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        onTap: () async {
                          DateTime initialDate = DateTime.tryParse(
                                  tglLahirController.text.trim()) ??
                              DateTime(2014, 1, 1);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final str = DateFormat('yyyy-MM-dd').format(picked);
                            setModalState(() => tglLahirController.text = str);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Alamat
                      TextFormField(
                        controller: alamatController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Tinggal',
                          hintText: 'Contoh: Jl. Merdeka No. 10',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: isEdit
                              ? 'Password Baru (Opsional)'
                              : 'Password Akun Siswa*',
                          hintText: isEdit
                              ? 'Kosongkan jika tidak ingin mengubah'
                              : 'Minimal 6 karakter',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setModalState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                        ),
                        validator: (val) {
                          if (!isEdit && (val == null || val.trim().isEmpty)) {
                            return 'Password untuk akun siswa wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: admin.isProcessing
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final payload = {
                                  'nis': nisController.text.trim(),
                                  'nama_murid': namaController.text.trim(),
                                  'jenis_kelamin': jenisKelamin,
                                  'id_paket': selectedPaketId,
                                  'level': level,
                                  'alamat': alamatController.text.trim().isEmpty
                                      ? '-'
                                      : alamatController.text.trim(),
                                  'tanggal_lahir':
                                      tglLahirController.text.trim().isEmpty
                                          ? '2014-01-01'
                                          : tglLahirController.text.trim(),
                                };

                                if (passwordController.text.trim().isNotEmpty) {
                                  payload['password'] =
                                      passwordController.text.trim();
                                }

                                try {
                                  if (isEdit) {
                                    final msg = await admin.updateSiswa(
                                      nisController.text.trim(),
                                      payload,
                                    );
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  } else {
                                    final msg = await admin.createSiswa(payload);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {});
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceFirst('Exception: ', '')),
                                      backgroundColor: AppTheme.danger,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: admin.isProcessing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Menyimpan Data...'),
                                ],
                              )
                            : Text(
                                isEdit ? 'Simpan Perubahan' : 'Tambah Siswa',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> s) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final nis = s['nis']?.toString() ?? '';
    final nama = s['nama_murid']?.toString() ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hapus Siswa?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data siswa "$nama" ($nis)?\n\nSeluruh riwayat tagihan dan bukti pembayaran terkait siswa ini akan dibersihkan.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final msg = await admin.deleteSiswa(nis);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus Siswa'),
          ),
        ],
      ),
    );
  }

  Color _getSppStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
      case 'sukses':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  Widget _buildMetricMiniCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusSppBottomSheet(Map<String, dynamic> s) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final nis = s['nis']?.toString() ?? '';
    final nama = s['nama_murid']?.toString() ?? '-';
    final namaPaket = s['nama_paket']?.toString() ?? 'Paket Bimbel';
    final level = s['level']?.toString() ?? '1';

    // Filter riwayat tagihan khusus siswa ini
    final studentTagihan = admin.tagihanList.where((t) {
      return t['nis']?.toString().trim().toLowerCase() == nis.trim().toLowerCase();
    }).toList();

    final unpaidBills = studentTagihan.where((t) {
      final st = (t['status_bayar'] ?? '').toString().toLowerCase();
      return st != 'lunas' && st != 'sukses';
    }).toList();

    final paidBills = studentTagihan.where((t) {
      final st = (t['status_bayar'] ?? '').toString().toLowerCase();
      return st == 'lunas' || st == 'sukses';
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),

              // Header Siswa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : 'S',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIS: $nis • Level $level • $namaPaket',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Ringkasan Status SPP
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricMiniCard(
                        title: 'Total Tagihan',
                        value: '${studentTagihan.length}',
                        color: AppTheme.primary,
                        icon: Icons.receipt_long_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricMiniCard(
                        title: 'Sudah Lunas',
                        value: '${paidBills.length}',
                        color: AppTheme.success,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricMiniCard(
                        title: 'Belum Lunas',
                        value: '${unpaidBills.length}',
                        color: unpaidBills.isNotEmpty ? AppTheme.danger : Colors.grey,
                        icon: Icons.error_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Summary Banner
              if (studentTagihan.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: unpaidBills.isEmpty
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: unpaidBills.isEmpty
                            ? AppTheme.success.withValues(alpha: 0.25)
                            : AppTheme.danger.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          unpaidBills.isEmpty
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: unpaidBills.isEmpty ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            unpaidBills.isEmpty
                                ? 'Status: Semua tagihan SPP siswa ini telah LUNAS.'
                                : 'Perhatian: Ada ${unpaidBills.length} tagihan SPP yang belum diselesaikan.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: unpaidBills.isEmpty ? AppTheme.success : AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Judul Daftar Tagihan
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian Tagihan SPP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${studentTagihan.length} Periode',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // List of Bills
              Expanded(
                child: studentTagihan.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_outlined,
                                  size: 40,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Belum Ada Tagihan SPP',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Belum ada tagihan SPP yang digenerate untuk siswa ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: studentTagihan.length,
                        itemBuilder: (context, idx) {
                          final bill = studentTagihan[idx];
                          final status = (bill['status_bayar'] ?? '').toString();
                          final nominal = double.tryParse(bill['nominal']?.toString() ?? '0') ?? 0;
                          final color = _getSppStatusColor(status);
                          final isPaid = status.toLowerCase() == 'lunas' || status.toLowerCase() == 'sukses';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isPaid
                                    ? AppTheme.border
                                    : color.withValues(alpha: 0.35),
                                width: isPaid ? 1 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPaid
                                        ? Icons.check_circle_rounded
                                        : Icons.receipt_long_rounded,
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill['periode']?.toString() ?? 'Periode -',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Jatuh Tempo: ${bill['jatuh_tempo'] ?? '-'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(nominal),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: color.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.check_rounded
                                            : Icons.access_time_rounded,
                                        size: 12,
                                        color: color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = key),
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Hitung counter untuk filter chip
    int totalBelumLunasCount = 0;
    int totalLunasCount = 0;
    for (final s in admin.siswaList) {
      final nis = s['nis']?.toString().trim().toLowerCase() ?? '';
      final sTags = admin.tagihanList.where((t) {
        return t['nis']?.toString().trim().toLowerCase() == nis;
      }).toList();

      if (sTags.isNotEmpty) {
        final hasUnpaid = sTags.any((t) {
          final st = (t['status_bayar'] ?? '').toString().toLowerCase();
          return st != 'lunas' && st != 'sukses';
        });
        if (hasUnpaid) {
          totalBelumLunasCount++;
        } else {
          totalLunasCount++;
        }
      }
    }

    final filtered = admin.siswaList.where((s) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          (s['nama_murid']?.toString().toLowerCase().contains(q) ?? false) ||
          (s['nis']?.toString().toLowerCase().contains(q) ?? false);
      if (!matchesQuery) return false;

      if (_statusFilter == 'semua') return true;

      final nis = s['nis']?.toString().trim().toLowerCase() ?? '';
      final sTags = admin.tagihanList.where((t) {
        return t['nis']?.toString().trim().toLowerCase() == nis;
      }).toList();

      final hasUnpaid = sTags.any((t) {
        final st = (t['status_bayar'] ?? '').toString().toLowerCase();
        return st != 'lunas' && st != 'sukses';
      });

      if (_statusFilter == 'belum_lunas') {
        return hasUnpaid;
      } else if (_statusFilter == 'lunas') {
        return sTags.isNotEmpty && !hasUnpaid;
      }
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari nama siswa atau NIS...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ),

          // Filter Chips Status SPP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('semua', 'Semua (${admin.siswaList.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('belum_lunas', 'Belum Lunas ($totalBelumLunasCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('lunas', 'Lunas ($totalLunasCount)'),
                ],
              ),
            ),
          ),

          // Info Bar Hasil Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Ditemukan ${filtered.length} siswa untuk "$_searchQuery"'
                      : 'Menampilkan ${filtered.length} siswa aktif',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _statusFilter != 'semua')
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _statusFilter = 'semua';
                      });
                    },
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  admin.loadSiswa(),
                  admin.loadPaket(),
                  admin.loadTagihan(),
                ]);
              },
              child: admin.isLoadingSiswa || admin.isLoadingTagihan
                  ? const Center(child: CircularProgressIndicator())
                  : admin.siswaError != null
                      ? _buildError(admin.siswaError!, () => admin.loadSiswa())
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search_rounded,
                                      size: 56, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada siswa yang cocok dengan "$_searchQuery"'
                                        : 'Tidak ada data siswa.',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final s = filtered[i];
                                final nis = s['nis']?.toString() ?? '';
                                final nominal = double.tryParse(
                                        s['nominal']?.toString() ?? '0') ??
                                    0;

                                // Cari riwayat tagihan siswa ini
                                final studentTagihan = admin.tagihanList.where((t) {
                                  return t['nis']?.toString().trim().toLowerCase() ==
                                      nis.trim().toLowerCase();
                                }).toList();

                                final unpaidBills = studentTagihan.where((t) {
                                  final st = (t['status_bayar'] ?? '').toString().toLowerCase();
                                  return st != 'lunas' && st != 'sukses';
                                }).toList();

                                final paidBills = studentTagihan.where((t) {
                                  final st = (t['status_bayar'] ?? '').toString().toLowerCase();
                                  return st == 'lunas' || st == 'sukses';
                                }).toList();

                                Widget statusSppBadge;
                                if (studentTagihan.isEmpty) {
                                  statusSppBadge = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline, size: 12, color: AppTheme.textMuted),
                                        SizedBox(width: 4),
                                        Text(
                                          'Belum Ada Tagihan',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (unpaidBills.isNotEmpty) {
                                  statusSppBadge = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.error_outline_rounded, size: 12, color: AppTheme.danger),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${unpaidBills.length} Belum Lunas',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.danger,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  statusSppBadge = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, size: 12, color: AppTheme.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lunas (${paidBills.length} bln)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showStatusSppBottomSheet(s),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor: AppTheme.primary
                                                      .withValues(alpha: 0.12),
                                                  child: Text(
                                                    (s['nama_murid']?.toString() ??
                                                            'S')
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: AppTheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        s['nama_murid']?.toString() ??
                                                            '-',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'NIS: ${s['nis'] ?? '-'} • ${s['jenis_kelamin'] ?? '-'}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme.textMuted,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${s['nama_paket'] ?? 'Paket -'} • ${currencyFormat.format(nominal)}/bln',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppTheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      statusSppBadge,
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Lvl ${s['level'] ?? '1'}',
                                                    style: const TextStyle(
                                                      color: AppTheme.accent,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    icon: const Icon(
                                                      Icons.receipt_long_rounded,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'Cek Status SPP',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppTheme.primary,
                                                      side: const BorderSide(
                                                        color: AppTheme.primary,
                                                        width: 1.2,
                                                      ),
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        _showStatusSppBottomSheet(s),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 20,
                                                    color: AppTheme.primary,
                                                  ),
                                                  tooltip: 'Edit Siswa',
                                                  onPressed: () =>
                                                      _showFormDialog(siswa: s),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 20,
                                                    color: AppTheme.danger,
                                                  ),
                                                  tooltip: 'Hapus Siswa',
                                                  onPressed: () =>
                                                      _showDeleteDialog(s),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

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
