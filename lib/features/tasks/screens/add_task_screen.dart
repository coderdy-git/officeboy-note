import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/navigation/swipe_back_detector.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../providers/tasks_provider.dart';

class TaskFieldData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  
  void dispose() {
    titleController.dispose();
    descController.dispose();
  }
}

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  int? _selectedStaffId;
  final TextEditingController _amountController = TextEditingController();
  final List<TaskFieldData> _taskFields = [TaskFieldData()];
  List<Staff> _staffList = [];
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final db = ref.read(databaseProvider);
    final staffs = await db.getAllStaffs();
    setState(() {
      _staffList = staffs;
      _isLoadingStaff = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final field in _taskFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _taskFields.add(TaskFieldData());
    });
  }

  void _removeField(int index) {
    if (_taskFields.length > 1) {
      setState(() {
        _taskFields[index].dispose();
        _taskFields.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Tambah Tugas'),
        ),
        body: _isLoadingStaff 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Catat Titipan Staff',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tugas ini merupakan titipan atau perintah dari staff yang bersangkutan.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                DropdownButtonFormField<int>(
                  value: _selectedStaffId,
                  decoration: InputDecoration(
                    labelText: 'Pilih Staff',
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _staffList.map((staff) {
                    return DropdownMenuItem(
                      value: staff.id,
                      child: Text(staff.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStaffId = val;
                    });
                  },
                ),
                
                const SizedBox(height: 24),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Total Uang Titipan (opsional)',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                ...List.generate(_taskFields.length, (index) {
                  final fieldData = _taskFields[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tugas ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (_taskFields.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.red),
                                onPressed: () => _removeField(index),
                                tooltip: 'Hapus field',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: fieldData.titleController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Judul Titipan (Contoh: Beli Kopi)',
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: fieldData.descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Lengkap (opsional)',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Icon(Icons.description_rounded),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Tambah Tugas Lainnya'),
                ),

                const SizedBox(height: 40),
                
                FilledButton(
                  onPressed: () async {
                    if (_selectedStaffId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih staff terlebih dahulu!')),
                      );
                      return;
                    }

                    final amountStr = _amountController.text.replaceAll(RegExp(r'\D'), '');
                    final totalAmount = amountStr.isEmpty ? 0 : int.parse(amountStr);

                    final tasksToSave = <Map<String, dynamic>>[];
                    for (int i = 0; i < _taskFields.length; i++) {
                      final field = _taskFields[i];
                      final title = _capitalizeWords(field.titleController.text.trim());
                      final desc = field.descController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Judul Titipan tidak boleh kosong!')),
                        );
                        return;
                      }
                      tasksToSave.add({
                        'title': title,
                        'description': desc,
                        'amount': i == 0 ? totalAmount : 0, 
                      });
                    }

                    await ref.read(tasksProvider.notifier).addTasksBatch(_selectedStaffId!, tasksToSave);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tugas berhasil ditambahkan!')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan Tugas', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
      ),
    );
  }
}
