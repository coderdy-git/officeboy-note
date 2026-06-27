import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

QueryExecutor createConnection(String filePath) {
  return NativeDatabase(File(filePath));
}
