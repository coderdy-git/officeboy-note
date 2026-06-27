import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/swipe_back_detector.dart';
import '../providers/tasks_provider.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);
    final numFormat = NumberFormat.decimalPattern('id_ID');

    return SwipeBackDetector(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 70,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                'Back',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          title: const Text('Daftar Titipan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_task_rounded),
              onPressed: () {
                Navigator.pushNamed(context, '/add-task');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: tasksState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (tasksList) {
            // Group tasks by staff
            final groupedByStaff = <int, List<TaskWithStaff>>{};
            for (var t in tasksList) {
              if (t.task.isDone) {
                continue; // Pindah ke riwayat transaksi
              }
              groupedByStaff.putIfAbsent(t.staff.id, () => []).add(t);
            }

            if (groupedByStaff.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Belum ada titipan aktif.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedByStaff.keys.length,
              itemBuilder: (context, index) {
                final staffId = groupedByStaff.keys.elementAt(index);
                final staffTasks = groupedByStaff[staffId]!;
                final staff = staffTasks.first.staff;
                
                // Urutkan titipan: yang belum selesai di atas
                staffTasks.sort((a, b) => a.task.isDone == b.task.isDone ? 0 : (a.task.isDone ? 1 : -1));

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withAlpha(10)),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    initiallyExpanded: true,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
                      child: Text(
                        staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      staff.totalDeposit > 0
                          ? '${staffTasks.length} titipan • Saldo: Rp ${numFormat.format(staff.totalDeposit)}'
                          : '${staffTasks.length} titipan',
                      style: TextStyle(
                        color: staff.totalDeposit > 0 ? Colors.green : Colors.grey.shade700,
                        fontWeight: staff.totalDeposit > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    children: [
                      const Divider(height: 1),
                      ...staffTasks.map((item) {
                        return _buildCompactTaskItem(context, item);
                      }),

                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactTaskItem(BuildContext context, TaskWithStaff item) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/task-detail', arguments: item.task.id);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withAlpha(10))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              item.task.isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: item.task.isDone ? Colors.green : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.task.title.isNotEmpty ? item.task.title : item.task.description,
                style: TextStyle(
                  fontWeight: item.task.isDone ? FontWeight.normal : FontWeight.w600,
                  fontSize: 15,
                  decoration: item.task.isDone ? TextDecoration.lineThrough : null,
                  color: item.task.isDone ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
