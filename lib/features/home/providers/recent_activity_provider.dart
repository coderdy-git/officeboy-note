import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/providers/attendance_provider.dart';

class RecentActivity {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  RecentActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

final recentActivityProvider = FutureProvider<List<RecentActivity>>((ref) async {
  final db = ref.watch(databaseProvider);
  
  final List<RecentActivity> activities = [];
  
  // 1. Absensi
  final records = await db.getAllRecords();
  for (final record in records) {
    if (record.checkIn != null) {
      activities.add(RecentActivity(
        title: 'Check In Absensi',
        subtitle: 'Absen masuk',
        timestamp: record.checkIn!,
        icon: Icons.login_rounded,
        color: Colors.green,
      ));
    }
    if (record.checkOut != null) {
      activities.add(RecentActivity(
        title: 'Check Out Absensi',
        subtitle: 'Absen pulang',
        timestamp: record.checkOut!,
        icon: Icons.logout_rounded,
        color: Colors.orange,
      ));
    }
  }

  // 2. Staffs
  final staffs = await db.getAllStaffs();
  for (final staff in staffs) {
    activities.add(RecentActivity(
      title: 'Staff Baru',
      subtitle: staff.name,
      timestamp: staff.createdAt,
      icon: Icons.person_add_rounded,
      color: Colors.blue,
    ));
  }

  // 3. Tasks
  final tasks = await db.getAllTasks();
  final staffMap = {for (var s in staffs) s.id: s.name};
  for (final task in tasks) {
    final staffName = staffMap[task.staffId] ?? 'Staff';
    activities.add(RecentActivity(
      title: 'Titipan Baru',
      subtitle: 'Dari: $staffName',
      timestamp: task.createdAt,
      icon: Icons.assignment_rounded,
      color: Colors.purple,
    ));
    if (task.isDone) {
      activities.add(RecentActivity(
        title: 'Titipan Selesai',
        subtitle: 'Milik: $staffName',
        timestamp: task.createdAt.add(const Duration(seconds: 1)), // Fake timestamp for completion
        icon: Icons.check_circle_rounded,
        color: Colors.teal,
      ));
    }
  }

  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return activities.take(10).toList();
});
