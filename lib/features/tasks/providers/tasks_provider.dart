import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../attendance/providers/attendance_provider.dart';

class TaskWithStaff {
  final TaskEntry task;
  final Staff staff;
  TaskWithStaff(this.task, this.staff);
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskWithStaff>>>((ref) {
  return TasksNotifier(ref.read(databaseProvider));
});

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskWithStaff>>> {
  final AppDatabase _db;

  TasksNotifier(this._db) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      // A simple implementation since we didn't add join in AppDatabase yet:
      // Fetch all tasks and staff, then map them in memory.
      final allTasks = await _db.getAllTasks();
      final allStaff = await _db.getAllStaffs();
      
      final staffMap = {for (var s in allStaff) s.id: s};
      
      final tasksWithStaff = allTasks.map((t) {
        return TaskWithStaff(t, staffMap[t.staffId]!);
      }).toList();
      
      state = AsyncValue.data(tasksWithStaff);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTasksBatch(int staffId, List<Map<String, dynamic>> tasksData) async {
    for (final data in tasksData) {
      await _db.insertTask(TasksCompanion(
        staffId: drift.Value(staffId),
        title: drift.Value(data['title']),
        description: drift.Value(data['description']),
        amount: drift.Value(data['amount'] ?? 0),
      ));
    }
    
    await loadTasks();
  }

  Future<void> addTask(int staffId, String description, {int amount = 0}) async {
    await _db.insertTask(TasksCompanion(
      staffId: drift.Value(staffId),
      description: drift.Value(description),
      amount: drift.Value(amount),
    ));
    await loadTasks();
  }

  Future<void> toggleTaskStatus(TaskEntry task) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await _db.updateTask(updatedTask);
    await loadTasks();
  }

  Future<void> completeTaskWithCost(TaskWithStaff item, int cost, {bool returnChange = true}) async {
    final staff = item.staff;
    int newDeposit = staff.totalDeposit;
    int newDebt = staff.totalDebt;
    
    final allTasks = await _db.getAllTasks();
    final otherActiveTasks = allTasks.where((t) => t.staffId == staff.id && !t.isDone && t.id != item.task.id).toList();
    
    int totalUangTitipan = item.task.amount + otherActiveTasks.fold(0, (sum, t) => sum + t.amount);
    final remaining = totalUangTitipan - cost;
    
    if (remaining > 0) {
      if (otherActiveTasks.isNotEmpty) {
        // Oper semua sisa uang ke salah satu tugas aktif berikutnya
        for (int i = 0; i < otherActiveTasks.length; i++) {
          final t = otherActiveTasks[i];
          if (i == 0) {
            await _db.updateTask(t.copyWith(amount: remaining));
          } else {
            if (t.amount != 0) await _db.updateTask(t.copyWith(amount: 0));
          }
        }
      } else {
        // Tidak ada tugas lain, eksekusi kembalian
        if (!returnChange) {
          // Sisa uang titipan masuk ke deposit
          newDeposit += remaining;
        } else {
          // Buat tugas baru sebagai pengingat untuk menyerahkan uang tunai
          final numFormat = NumberFormat.decimalPattern('id_ID');
          await _db.insertTask(TasksCompanion(
            staffId: drift.Value(staff.id),
            title: drift.Value('Kembalian Rp ${numFormat.format(remaining)}'),
            description: drift.Value('Serahkan kembalian dari: ${item.task.title.isNotEmpty ? item.task.title : 'Titipan sebelumnya'}'),
            amount: const drift.Value(0),
            cost: const drift.Value(0),
            isDone: const drift.Value(false),
          ));
        }
      }
    } else if (remaining < 0) {
      // Uang habis, sisa kurangnya masuk hutang
      newDebt += remaining.abs();
      // Pastikan semua task lain uang titipannya jadi 0 karena sudah terpakai
      for (var t in otherActiveTasks) {
        if (t.amount != 0) await _db.updateTask(t.copyWith(amount: 0));
      }
    } else {
      // remaining == 0
      for (var t in otherActiveTasks) {
        if (t.amount != 0) await _db.updateTask(t.copyWith(amount: 0));
      }
    }
    
    final updatedStaff = staff.copyWith(totalDeposit: newDeposit, totalDebt: newDebt);
    await _db.updateStaff(updatedStaff);
    
    final updatedTask = item.task.copyWith(isDone: true, cost: cost, amount: 0); // amount di task yang selesai jadi 0 karena sudah dihitung di total
    await _db.updateTask(updatedTask);
    
    await loadTasks();
  }

  Future<void> returnChange(int staffId) async {
    final staff = await _db.getStaff(staffId);
    final updatedStaff = staff.copyWith(totalDeposit: 0);
    await _db.updateStaff(updatedStaff);
    await loadTasks();
  }

  Future<void> payDebt(int staffId, int paymentAmount, {bool useDeposit = false}) async {
    final staff = await _db.getStaff(staffId);
    int newDeposit = staff.totalDeposit;
    
    int totalPayment = paymentAmount;
    if (useDeposit && newDeposit > 0) {
      totalPayment += newDeposit;
      newDeposit = 0; // Deposit digunakan semua untuk bayar
    }

    int newDebt = staff.totalDebt - totalPayment;

    if (newDebt < 0) {
      newDeposit += newDebt.abs(); // Sisa lebihan pembayaran masuk lagi ke deposit
      newDebt = 0;
    }

    final updatedStaff = staff.copyWith(totalDebt: newDebt, totalDeposit: newDeposit);
    await _db.updateStaff(updatedStaff);

    // Tandai transaksi hutang menjadi lunas (amount tidak lagi 0)
    final allTasks = await _db.getAllTasks();
    var unpaidDebtTasks = allTasks.where((t) => t.staffId == staffId && t.isDone && t.amount == 0).toList();
    // Urutkan dari yang paling lama
    unpaidDebtTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int remainingPayment = totalPayment;
    
    for (var task in unpaidDebtTasks) {
      if (remainingPayment <= 0) break;
      
      if (remainingPayment >= task.cost) {
        remainingPayment -= task.cost;
        await _db.updateTask(task.copyWith(amount: task.cost));
      } else {
        await _db.updateTask(task.copyWith(amount: remainingPayment));
        remainingPayment = 0;
      }
    }

    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    await loadTasks();
  }
}
