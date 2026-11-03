import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

const List<String> kNamaBulan = [
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

Future<String?> showMonthYearPickerDialog(
  BuildContext context, {
  String? initialPeriode,
}) async {
  final now = DateTime.now();
  int selectedYear = now.year;
  int selectedMonth = now.month;

  if (initialPeriode != null && initialPeriode.trim().isNotEmpty) {
    final parts = initialPeriode.trim().split(' ');
    if (parts.length >= 2) {
      final mIdx = kNamaBulan.indexWhere(
          (m) => m.toLowerCase() == parts[0].toLowerCase());
      if (mIdx != -1) selectedMonth = mIdx + 1;
      final y = int.tryParse(parts[1]);
      if (y != null) selectedYear = y;
    }
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setPickerState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Tahun Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: () => setPickerState(() => selectedYear--),
                ),
                Text(
                  '$selectedYear',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Tahun Berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: () => setPickerState(() => selectedYear++),
                ),
              ],
            ),
            content: SizedBox(
              width: 310,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (c, idx) {
                  final monthNum = idx + 1;
                  final isCurrentMonth =
                      (monthNum == now.month && selectedYear == now.year);
                  final isSelected = (monthNum == selectedMonth);
                  return Material(
                    color: isSelected
                        ? AppTheme.primary
                        : (isCurrentMonth
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final chosenMonth = kNamaBulan[idx];
                        Navigator.pop(ctx, '$chosenMonth $selectedYear');
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : (isCurrentMonth
                                    ? AppTheme.primary.withValues(alpha: 0.4)
                                    : AppTheme.border),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          kNamaBulan[idx],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: (isSelected || isCurrentMonth)
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isCurrentMonth
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );
    },
  );
}
