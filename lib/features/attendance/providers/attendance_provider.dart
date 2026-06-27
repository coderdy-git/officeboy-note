import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/database.dart';
import '../../../core/backup/google_drive_service.dart';
import '../../settings/providers/auth_provider.dart';

/// State untuk layar home absensi.
class AttendanceState {
  final bool isLoading;
  final AttendanceRecord? todayRecord;
  final bool isCheckedIn;

  const AttendanceState({
    this.isLoading = true,
    this.todayRecord,
    this.isCheckedIn = false,
  });

  AttendanceState copyWith({
    bool? isLoading,
    AttendanceRecord? todayRecord,
    bool? isCheckedIn,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      todayRecord: todayRecord ?? this.todayRecord,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

/// Provider untuk database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Notifier untuk mengelola absensi hari ini.
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AppDatabase _db;
  final GoogleDriveService _driveService;

  AttendanceNotifier(this._db, this._driveService) : super(const AttendanceState()) {
    _loadTodayRecord();
  }

  /// Muat record absensi hari ini dari database.
  Future<void> _loadTodayRecord() async {
    state = state.copyWith(isLoading: true);
    try {
      final record = await _db.getTodayRecord();
      state = AttendanceState(
        isLoading: false,
        todayRecord: record,
        isCheckedIn: record != null && record.checkOut == null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Check-in: catat waktu masuk.
  Future<void> checkIn() async {
    final now = DateTime.now();
    await _db.insertRecord(
      AttendanceRecordsCompanion(
        date: Value(DateTime(now.year, now.month, now.day)),
        checkIn: Value(now),
      ),
    );
    await _loadTodayRecord();
    _triggerAutoBackup();
  }

  /// Check-out: catat waktu keluar pada record hari ini.
  Future<void> checkOut() async {
    final record = state.todayRecord;
    if (record == null) return;

    final now = DateTime.now();
    await (_db.update(_db.attendanceRecords)
      ..where((t) => t.id.equals(record.id)))
        .write(AttendanceRecordsCompanion(checkOut: Value(now)));

    await _loadTodayRecord();
    _triggerAutoBackup();
  }

  /// Backup secara diam-diam (otomatis) setiap ada perubahan absen.
  void _triggerAutoBackup() {
    _driveService.backup().catchError((e) {
      // Abaikan jika error (misal offline), karena fitur ini berjalan di background
      print("Auto-backup failed: $e");
      return "";
    });
  }
}

/// Provider untuk attendance state.
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final db = ref.watch(databaseProvider);
  final driveService = ref.watch(googleDriveServiceProvider);
  return AttendanceNotifier(db, driveService);
});
