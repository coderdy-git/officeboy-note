import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/swipe_back_detector.dart';
import '../providers/tasks_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final TextEditingController _costController = TextEditingController();

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  void _showCompletionDialog(TaskWithStaff item, List<TaskWithStaff> tasksList) {
    final numFormat = NumberFormat.decimalPattern('id_ID');
    _costController.clear();
    
    final allActiveTasksForStaff = tasksList.where((t) => t.staff.id == item.staff.id && !t.task.isDone).toList();
    final totalAmount = allActiveTasksForStaff.fold(0, (sum, t) => sum + t.task.amount);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Penyelesaian Titipan', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.money_rounded, color: Colors.green),
                      const SizedBox(width: 12),
                      Text('Uang Titipan: Rp ${numFormat.format(totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Total Biaya / Pengeluaran (Rp)',
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.shopping_cart_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      final costStr = _costController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final cost = int.tryParse(costStr) ?? 0;
                      final remaining = totalAmount - cost;
                      
                      if (remaining > 0) {
                        final otherActiveTasks = tasksList.where((t) => t.staff.id == item.staff.id && !t.task.isDone && t.task.id != item.task.id).toList();
                        
                        if (otherActiveTasks.isNotEmpty) {
                          // Otomatis oper sisa uang ke tugas berikutnya tanpa dialog
                          ref.read(tasksProvider.notifier).completeTaskWithCost(item, cost, returnChange: false);
                          Navigator.pop(ctx);
                          if (context.mounted) Navigator.pop(context);
                        } else {
                          // Tidak ada tugas lain, tampilkan dialog kembalian
                          showDialog(
                            context: ctx,
                            barrierDismissible: false,
                            builder: (ctx2) => AlertDialog(
                              title: const Text('Ada Kembalian'),
                              content: Text('Terdapat sisa uang titipan sebesar Rp ${numFormat.format(remaining)}.\nApakah akan dikembalikan langsung secara tunai, atau disimpan ke saldo deposit?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    ref.read(tasksProvider.notifier).completeTaskWithCost(item, cost, returnChange: false);
                                    Navigator.pop(ctx2); 
                                    Navigator.pop(ctx);  
                                    if (context.mounted) Navigator.pop(context); 
                                  }, 
                                  child: const Text('Masuk Deposit')
                                ),
                                FilledButton(
                                  onPressed: () {
                                    ref.read(tasksProvider.notifier).completeTaskWithCost(item, cost, returnChange: true);
                                    Navigator.pop(ctx2);
                                    Navigator.pop(ctx);
                                    if (context.mounted) Navigator.pop(context);
                                  }, 
                                  child: const Text('Dikembalikan Tunai')
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        ref.read(tasksProvider.notifier).completeTaskWithCost(item, cost, returnChange: false);
                        Navigator.pop(ctx);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskId = ModalRoute.of(context)?.settings.arguments as int?;
    
    if (taskId == null) {
      return const Scaffold(body: Center(child: Text('Titipan tidak ditemukan')));
    }

    final tasksState = ref.watch(tasksProvider);
    final tasksList = tasksState.value ?? [];
    
    // Find the task in the reactive list
    final itemIndex = tasksList.indexWhere((t) => t.task.id == taskId);
    if (itemIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Titipan')),
        body: const Center(child: Text('Titipan sudah dihapus atau tidak ditemukan.')),
      );
    }
    
    final item = tasksList[itemIndex];
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID');
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
          title: const Text('Detail Titipan'),
          actions: [
            if (!item.task.isDone)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Titipan?'),
                    content: const Text('Apakah Anda yakin ingin menghapus titipan ini secara permanen?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          ref.read(tasksProvider.notifier).deleteTask(item.task.id);
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close detail screen
                        }, 
                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: item.task.isDone 
                      ? Colors.green.withAlpha(30) 
                      : Theme.of(context).colorScheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.task.isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  size: 64,
                  color: item.task.isDone ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Status Text
            Center(
              child: Text(
                item.task.isDone ? 'Sudah Selesai' : 'Belum Selesai',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: item.task.isDone ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Card Detail
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withAlpha(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DARI STAFF', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(item.staff.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  const Text('WAKTU DIBUAT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(dateFormat.format(item.task.createdAt), style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text('JUDUL TITIPAN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    item.task.title.isNotEmpty ? item.task.title : '-',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const Divider(height: 32),
                  const Text('UANG TITIPAN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final allActiveTasksForStaff = tasksList.where((t) => t.staff.id == item.staff.id && !t.task.isDone).toList();
                      final totalAmount = allActiveTasksForStaff.fold(0, (sum, t) => sum + t.task.amount);
                      
                      return Text(
                        'Rp ${numFormat.format(totalAmount)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      );
                    }
                  ),
                  if (item.task.description.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text('DESKRIPSI TITIPAN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      item.task.description,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Builder(
              builder: (context) {
                if (item.task.isDone) {
                  return const SizedBox.shrink();
                }

                final isKembalian = item.task.title.startsWith('Kembalian Rp ');

                if (isKembalian) {
                  return FilledButton(
                    onPressed: () {
                      ref.read(tasksProvider.notifier).completeTaskWithCost(item, 0, returnChange: false);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kembalian Diberikan', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return FilledButton(
                  onPressed: () {
                    _showCompletionDialog(item, tasksList);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Selesaikan Titipan', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
