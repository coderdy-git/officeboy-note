import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'tables.dart';
import 'connection.dart';

part 'database.g.dart';

@DriftDatabase(tables: [AttendanceRecords, Staffs, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openDatabase());

  static QueryExecutor _openDatabase() {
    const dbName = 'office_boy_note.db';
    if (kIsWeb) {
      return openConnection(dbName);
    }
    // Native: lazy so path_provider has time to initialize
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, dbName);
      return openConnection(path);
    });
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(staffs);
        }
        if (from < 3) {
          await m.createTable(tasks);
        }
        if (from < 4) {
          await m.addColumn(tasks, tasks.amount);
        }
        if (from < 5) {
          await m.addColumn(tasks, tasks.title);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ─── Queries ─────────────────────────────────────────────

  /// Get all attendance records ordered by date (newest first).
  Future<List<AttendanceRecord>> getAllRecords() {
    return (select(attendanceRecords)
      ..orderBy(
          [(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  /// Get records for a specific month.
  Future<List<AttendanceRecord>> getRecordsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final startVar = Variable<DateTime>(start);
    final endVar = Variable<DateTime>(end);
    return (select(attendanceRecords)
      ..where((t) => t.date.isBetween(startVar, endVar))
      ..orderBy(
          [(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  /// Get today's record if it exists.
  Future<AttendanceRecord?> getTodayRecord() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final startVar = Variable<DateTime>(start);
    final endVar = Variable<DateTime>(end);
    return (select(attendanceRecords)
      ..where((t) => t.date.isBetween(startVar, endVar))
      ..limit(1))
        .getSingleOrNull();
  }

  /// Insert a new attendance record.
  Future<int> insertRecord(AttendanceRecordsCompanion entry) {
    return into(attendanceRecords).insert(entry);
  }

  /// Delete a record by id.
  Future<int> deleteRecord(int id) {
    return (delete(attendanceRecords)..where((t) => t.id.equals(id))).go();
  }

  /// Get all records as JSON (for backup).
  Future<List<Map<String, dynamic>>> exportAllRecords() async {
    final records = await getAllRecords();
    return records
        .map((r) => {
              'id': r.id,
              'date': r.date.toIso8601String(),
              'checkIn': r.checkIn?.toIso8601String(),
              'checkOut': r.checkOut?.toIso8601String(),
              'notes': r.notes,
            })
        .toList();
  }

  /// Import records from JSON (for restore).
  Future<int> importRecords(List<Map<String, dynamic>> jsonList) async {
    int count = 0;
    for (final json in jsonList) {
      try {
        // Use insertOnConflictUpdate to handle duplicate IDs
        await into(attendanceRecords)
            .insertOnConflictUpdate(
              AttendanceRecordsCompanion(
                id: json['id'] != null
                    ? Value(json['id'] as int)
                    : const Value.absent(),
                date: Value(DateTime.parse(json['date'] as String)),
                checkIn: Value(json['checkIn'] != null
                    ? DateTime.parse(json['checkIn'] as String)
                    : null),
                checkOut: Value(json['checkOut'] != null
                    ? DateTime.parse(json['checkOut'] as String)
                    : null),
                notes: Value(json['notes'] as String?),
              ),
            );
        count++;
      } catch (_) {
        // Skip invalid records
      }
    }
    return count;
  }

  // ─── Staff Queries ─────────────────────────────────────────────
  
  Future<List<Staff>> getAllStaffs() {
    return (select(staffs)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Staff> getStaff(int id) {
    return (select(staffs)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertStaff(StaffsCompanion entry) {
    return into(staffs).insert(entry);
  }

  Future<int> deleteStaff(int id) {
    return (delete(staffs)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> updateStaff(Staff entry) {
    return update(staffs).replace(entry);
  }

  // ─── Tasks Queries ─────────────────────────────────────────────
  
  Future<List<TaskEntry>> getAllTasks() {
    return (select(tasks)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
  }

  Future<int> insertTask(TasksCompanion entry) {
    return into(tasks).insert(entry);
  }

  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> updateTask(TaskEntry entry) {
    return update(tasks).replace(entry);
  }

  // ─── Backup & Restore ──────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final attRecords = await getAllRecords();
    final attJson = attRecords.map((r) => {
      'id': r.id,
      'date': r.date.toIso8601String(),
      'checkIn': r.checkIn?.toIso8601String(),
      'checkOut': r.checkOut?.toIso8601String(),
      'notes': r.notes,
    }).toList();

    final stfRecords = await getAllStaffs();
    final stfJson = stfRecords.map((s) => {
      'id': s.id,
      'name': s.name,
      'phone': s.phone,
      'totalDeposit': s.totalDeposit,
      'totalDebt': s.totalDebt,
      'createdAt': s.createdAt.toIso8601String(),
    }).toList();

    return {
      'attendance': attJson,
      'staffs': stfJson,
    };
  }

  Future<int> importAllData(Map<String, dynamic> data) async {
    int count = 0;
    
    // Import Attendance
    if (data.containsKey('attendance')) {
      final attList = (data['attendance'] as List).cast<Map<String, dynamic>>();
      count += await importRecords(attList);
    } else if (data.containsKey('id')) {
      // Handle legacy format where data might be a single list of attendance records
      // Wait, google_drive_service passed a List previously. If old format is used, google_drive_service will pass it to importRecords.
    }

    // Import Staffs
    if (data.containsKey('staffs')) {
      final stfList = (data['staffs'] as List).cast<Map<String, dynamic>>();
      for (final json in stfList) {
        try {
          await into(staffs).insertOnConflictUpdate(
            StaffsCompanion(
              id: json['id'] != null ? Value(json['id'] as int) : const Value.absent(),
              name: Value(json['name'] as String),
              phone: Value(json['phone'] as String),
              totalDeposit: Value(json['totalDeposit'] as int? ?? 0),
              totalDebt: Value(json['totalDebt'] as int? ?? 0),
              createdAt: Value(DateTime.parse(json['createdAt'] as String)),
            ),
          );
          count++;
        } catch (_) {}
      }
    }
    return count;
  }

  Future<void> clearAllData() async {
    await delete(attendanceRecords).go();
    await delete(tasks).go();
    await delete(staffs).go();
  }

  /// Dispose the database connection.
  @override
  Future<void> close() => super.close();
}
