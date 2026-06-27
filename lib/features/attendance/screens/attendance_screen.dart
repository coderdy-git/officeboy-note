import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/swipe_back_detector.dart';
import '../providers/attendance_provider.dart';
import '../widgets/check_button.dart';

DateTime? _lastSnackBarTime;

/// Layar utama: tombol absen dan info hari ini.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final isTooEarly = today.hour < 6;
    final isCompleted = state.todayRecord?.checkIn != null && state.todayRecord?.checkOut != null;
    
    return SwipeBackDetector(
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
          title: const Text(
            'Absensi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [const Color(0xFFE3F2FD), const Color(0xFFF8F9FA)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tanggal hari ini
                  Text(
                    dateFormat.format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 60),
      
                  // Tombol Check-In / Check-Out
                  CheckButton(
                    isCheckedIn: state.isCheckedIn,
                    isLoading: state.isLoading,
                    isCompleted: isCompleted,
                    isTooEarly: isTooEarly,
                    onPressed: () async {
                      final nowTime = DateTime.now();
                      if (_lastSnackBarTime != null && nowTime.difference(_lastSnackBarTime!).inSeconds < 2) {
                        return; // Cegah spam klik jika jaraknya kurang dari 2 detik
                      }
                      _lastSnackBarTime = nowTime;
      
                      if (isCompleted) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Anda sudah absen masuk dan keluar hari ini!')),
                          );
                        }
                        return;
                      }
                      if (isTooEarly) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Absen hanya bisa dilakukan setelah jam 06:00 pagi!')),
                          );
                        }
                        return;
                      }
      
                      try {
                        if (state.isCheckedIn) {
                          await notifier.checkOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Check-out berhasil!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          await notifier.checkIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Check-in berhasil!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Gagal: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
      
                  const SizedBox(height: 60),
      
                  // Info waktu hari ini
                  if (state.todayRecord != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withAlpha(200),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Status Hari Ini',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _InfoItem(
                                label: 'Masuk',
                                value: state.todayRecord!.checkIn != null
                                    ? timeFormat.format(state.todayRecord!.checkIn!)
                                    : '--:--',
                                icon: Icons.login_rounded,
                                color: Colors.green,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              _InfoItem(
                                label: 'Keluar',
                                value: state.todayRecord!.checkOut != null
                                    ? timeFormat.format(state.todayRecord!.checkOut!)
                                    : '--:--',
                                icon: Icons.logout_rounded,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.white60,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Belum ada catatan hari ini',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget kecil untuk menampilkan info (label + value).
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
