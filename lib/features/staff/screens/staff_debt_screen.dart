import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database.dart';
import '../../../core/navigation/swipe_back_detector.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../attendance/providers/attendance_provider.dart';

class StaffDebtScreen extends ConsumerStatefulWidget {
  const StaffDebtScreen({super.key});

  @override
  ConsumerState<StaffDebtScreen> createState() => _StaffDebtScreenState();
}

class _StaffDebtScreenState extends ConsumerState<StaffDebtScreen> {
  Staff? _staff;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Staff) {
        _staff = args;
      }
      _isInit = true;
    }
  }

  Future<void> _sendWhatsApp(List<TaskWithStaff> hutangTasks, int rawTotalHutang, NumberFormat numFormat) async {
    if (_staff == null) return;
    
    // Format phone number
    String phone = _staff!.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (phone.isNotEmpty && !phone.startsWith('62')) {
      phone = '62$phone';
    }

    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor telepon staff tidak valid.')));
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String defaultTemplate = '''*Rincian Hutang {nama}*
====================
{rincian_hutang}
====================
Total Hutang: Rp {total_hutang}
Total Deposit: - Rp {total_deposit}
Sisa Hutang Bersih: *Rp {sisa_hutang}*

Harap segera dibayarkan. Terima kasih.''';
    
    String template = prefs.getString('wa_template') ?? defaultTemplate;

    final StringBuffer rincianSb = StringBuffer();
    for (var t in hutangTasks) {
      final title = t.task.title.isNotEmpty ? t.task.title : t.task.description;
      final date = DateFormat('dd/MM/yyyy').format(t.task.createdAt);
      rincianSb.writeln('- $date: $title (Rp ${numFormat.format(t.task.cost)})');
    }

    String finalMessage = template
        .replaceAll('{nama}', _staff!.name)
        .replaceAll('{rincian_hutang}', rincianSb.toString().trimRight())
        .replaceAll('{total_hutang}', numFormat.format(rawTotalHutang))
        .replaceAll('{total_deposit}', numFormat.format(_staff!.totalDeposit))
        .replaceAll('{sisa_hutang}', numFormat.format(rawTotalHutang));

    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(finalMessage)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
      }
    }
  }

  void _showPaymentModal(BuildContext context, WidgetRef ref, int rawTotalHutang) {
    if (_staff == null) return;
    
    final initialText = rawTotalHutang > 0 ? NumberFormat.decimalPattern('id_ID').format(rawTotalHutang) : '';
    final TextEditingController amountController = TextEditingController(text: initialText);
    bool useDeposit = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bayar Hutang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_staff!.totalDeposit > 0) ...[
                    SwitchListTile(
                      title: const Text('Gunakan Saldo Deposit'),
                      subtitle: Text('Potong Rp ${NumberFormat.decimalPattern('id_ID').format(_staff!.totalDeposit)} dari hutang'),
                      value: useDeposit,
                      onChanged: (val) {
                        setStateModal(() {
                          useDeposit = val;
                          if (val) {
                            final sisa = rawTotalHutang - _staff!.totalDeposit;
                            amountController.text = sisa > 0 ? NumberFormat.decimalPattern('id_ID').format(sisa) : '0';
                          } else {
                            amountController.text = rawTotalHutang > 0 ? NumberFormat.decimalPattern('id_ID').format(rawTotalHutang) : '0';
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal Bayar Tambahan (Cash)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final rawValue = amountController.text.replaceAll(RegExp(r'\D'), '');
                        final amount = int.tryParse(rawValue) ?? 0;
                        if (amount > 0 || useDeposit) {
                          Navigator.pop(ctx);
                          await ref.read(tasksProvider.notifier).payDebt(_staff!.id, amount, useDeposit: useDeposit);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dicatat')));
                            Navigator.pop(context); // Kembali ke halaman detail staff
                          }
                        }
                      },
                      child: const Text('Simpan Pembayaran'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
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
          title: Text('Hutang ${_staff!.name}'),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.green),
                  tooltip: 'Kirim via WhatsApp',
                  onPressed: () {
                    final tasksState = ref.read(tasksProvider);
                    final allStaffTasks = tasksState.value?.where((t) => t.staff.id == _staff!.id && t.task.isDone).toList() ?? [];
                    final hutangTasks = allStaffTasks.where((t) => t.task.amount == 0).toList();
                    final int rawTotalHutang = hutangTasks.fold(0, (sum, item) => sum + item.task.cost);
                    
                    _sendWhatsApp(hutangTasks, rawTotalHutang, NumberFormat.decimalPattern('id_ID'));
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final tasksState = ref.watch(tasksProvider);
            final allStaffTasks = tasksState.value?.where((t) => t.staff.id == _staff!.id && t.task.isDone).toList() ?? [];
            final numFormat = NumberFormat.decimalPattern('id_ID');

            // Hutang -> tidak ada uang titipan (amount == 0)
            final hutangTasks = allStaffTasks.where((t) => t.task.amount == 0).toList();

            if (hutangTasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Tidak ada riwayat hutang.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              );
            }

            final int rawTotalHutang = hutangTasks.fold(0, (sum, item) => sum + item.task.cost);
            final int totalDeposit = _staff!.totalDeposit;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade50),
                          children: const [
                            Padding(padding: EdgeInsets.all(12.0), child: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12.0), child: Text('Titipan', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12.0), child: Text('Hutang', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          ]
                        ),
                        ...hutangTasks.map((t) => TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(12.0), child: Text(DateFormat('dd/MM').format(t.task.createdAt))),
                            Padding(padding: const EdgeInsets.all(12.0), child: Text(t.task.title.isNotEmpty ? t.task.title : t.task.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Padding(padding: const EdgeInsets.all(12.0), child: Text('Rp ${numFormat.format(t.task.cost)}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.red))),
                          ]
                        )),
                      ]
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ]
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Hutang', style: TextStyle(color: Colors.grey)),
                            Text('Rp ${numFormat.format(rawTotalHutang)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Deposit', style: TextStyle(color: Colors.grey)),
                            Text('- Rp ${numFormat.format(totalDeposit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sisa Hutang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Rp ${numFormat.format(rawTotalHutang)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              _showPaymentModal(context, ref, rawTotalHutang);
                            },
                            icon: const Icon(Icons.payment_rounded),
                            label: const Text('Bayar Semua', style: TextStyle(fontSize: 16)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
