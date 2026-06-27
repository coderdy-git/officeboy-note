import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import 'attendance_provider.dart';

/// Provider untuk riwayat absensi berdasarkan bulan & tahun.
/// Mengembalikan Map dengan key "YYYY-MM" sebagai group label,
/// dan value berupa list record.
final historyProvider =
    FutureProvider.family<Map<String, List<AttendanceRecord>>, DateTime>(
        (ref, monthDate) async {
  final db = ref.watch(databaseProvider);
  final year = monthDate.year;
  final month = monthDate.month;

  final records = await db.getRecordsForMonth(year, month);

  // Group by date
  final Map<String, List<AttendanceRecord>> grouped = {};
  for (final record in records) {
    final key =
        '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(record);
  }

  return grouped;
});

/// Provider untuk mendapatkan semua record dalam bentuk flat list.
final allRecordsProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllRecords();
});

/// Format durasi antara check-in dan check-out.
String formatDuration(AttendanceRecord record) {
  if (record.checkIn == null) return '-';
  final end = record.checkOut ?? DateTime.now();
  final duration = end.difference(record.checkIn!);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours > 0) return '${hours}j ${minutes}m';
  return '${minutes}m';
}
