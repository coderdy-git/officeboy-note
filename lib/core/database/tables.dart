import 'package:drift/drift.dart';

/// Table definition for attendance records.
class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get checkIn => dateTime().nullable()();
  DateTimeColumn get checkOut => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Table definition for staff records.
class Staffs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  IntColumn get totalDeposit => integer().withDefault(const Constant(0))();
  IntColumn get totalDebt => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table definition for tasks assigned to staff.
@DataClassName('TaskEntry')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get staffId => integer().references(Staffs, #id)();
  TextColumn get title => text().withLength(min: 1, max: 255).withDefault(const Constant(''))();
  TextColumn get description => text().withLength(max: 255).withDefault(const Constant(''))();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  IntColumn get cost => integer().withDefault(const Constant(0))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
