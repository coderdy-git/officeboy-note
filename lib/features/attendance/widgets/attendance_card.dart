import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';

/// Card untuk menampilkan satu record absensi.
class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final checkInStr =
        record.checkIn != null ? timeFormat.format(record.checkIn!) : '--:--';
    final checkOutStr = record.checkOut != null
        ? timeFormat.format(record.checkOut!)
        : '--:--';

    final isCompleted = record.checkOut != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(20),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withAlpha(30)
                : Colors.orange.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(record.date),
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              Text(
                DateFormat('MMM').format(record.date),
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.login_rounded, size: 20, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(checkInStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(checkOutStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        subtitle: record.notes != null && record.notes!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  record.notes!,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        trailing: record.notes != null && record.notes!.isNotEmpty
            ? Icon(Icons.sticky_note_2_rounded,
                color: Theme.of(context).colorScheme.primary.withAlpha(150))
            : null,
      ),
    );
  }
}
