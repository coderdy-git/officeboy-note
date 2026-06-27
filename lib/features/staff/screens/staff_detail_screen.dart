import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/swipe_back_detector.dart';
import '../../../core/database/database.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import 'package:intl/intl.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  const StaffDetailScreen({super.key});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  Staff? _staff;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_staff == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Staff) {
        _staff = args;
        _nameController.text = args.name;
        _phoneController.text = args.phone;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _refreshStaff() async {
    if (_staff != null) {
      final db = ref.read(databaseProvider);
      final updatedStaff = await db.getStaff(_staff!.id);
      if (mounted) {
        setState(() {
          _staff = updatedStaff;
        });
      }
    }
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Data Staff',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final phone = _phoneController.text.trim();
                
                if (name.isNotEmpty && _staff != null) {
                  final db = ref.read(databaseProvider);
                  
                  final updatedStaff = _staff!.copyWith(
                    name: name,
                    phone: phone,
                  );
                  
                  await db.updateStaff(updatedStaff);
                  
                  setState(() {
                    _staff = updatedStaff;
                  });
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data staff berhasil diperbarui!')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_staff == null) {
      return const Scaffold(body: Center(child: Text('Data staff tidak ditemukan')));
    }

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
            title: Text(_staff!.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _showEditModal,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Consumer(
            builder: (context, ref, child) {
              final tasksState = ref.watch(tasksProvider);
              // Semua task yang sudah selesai
              final allStaffTasks = tasksState.value?.where((t) => t.staff.id == _staff!.id && t.task.isDone).toList() ?? [];
              final numFormat = NumberFormat.decimalPattern('id_ID');

              final transaksiTasks = allStaffTasks;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                          child: Text(
                            _staff!.name.isNotEmpty ? _staff!.name[0].toUpperCase() : 'S',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _staff!.phone.isNotEmpty ? _staff!.phone : 'Tidak ada nomor telepon',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Deposit', style: TextStyle(fontSize: 16)),
                                    Text('Rp ${numFormat.format(_staff!.totalDeposit)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Hutang', style: TextStyle(fontSize: 16)),
                                    Text('Rp ${numFormat.format(_staff!.totalDebt)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Topup coming soon!')));
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                label: const Text('Topup'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(context, '/staff-debt', arguments: _staff);
                                  _refreshStaff();
                                },
                                icon: const Icon(Icons.payment_rounded),
                                label: const Text('Bayar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: _buildTaskList(transaksiTasks, numFormat),
                  ),
                ],
              );
            },
          ),
        ),
    );
  }

  Widget _buildTaskList(List<TaskWithStaff> tasks, NumberFormat numFormat) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada data.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }
    // Group tasks by date
    final groupedTasks = <String, List<TaskWithStaff>>{};
    for (var t in tasks) {
      final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(t.task.createdAt);
      groupedTasks.putIfAbsent(dateStr, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTasks.length,
      itemBuilder: (context, index) {
        final dateStr = groupedTasks.keys.elementAt(index);
        final dateTasks = groupedTasks[dateStr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...dateTasks.map((t) {
              final bool isDebt = t.task.amount == 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black.withAlpha(20)),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(context, '/task-detail', arguments: t.task.id);
                  },
                  leading: Icon(isDebt ? Icons.money_off_rounded : Icons.history_rounded, color: isDebt ? Colors.red : Colors.grey),
                  title: Text(t.task.title.isNotEmpty ? t.task.title : t.task.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: isDebt ? null : Text(DateFormat('HH:mm').format(t.task.createdAt)),
                  trailing: Text(
                    isDebt 
                      ? 'Rp ${numFormat.format(t.task.cost)}' 
                      : 'Rp ${numFormat.format(t.task.amount)}',
                    style: TextStyle(
                      color: isDebt ? Colors.red : Colors.green, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(), // Needs toList() because spread operator is used
            if (index < groupedTasks.length - 1)
              const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}


