import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../attendance/providers/history_provider.dart';
import '../../tasks/providers/tasks_provider.dart';

/// Layar pengaturan: Login Google, Backup, Restore.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSignedIn = authState != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Section: Akun Google ───────────────────────
          _SectionHeader(title: 'Akun Google'),
          const SizedBox(height: 8),

          if (isSignedIn) ...[
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: authState.photoUrl != null
                          ? NetworkImage(authState.photoUrl!)
                          : null,
                      child: authState.photoUrl == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.displayName ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authState.email,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Sign in button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Login dengan Google untuk melakukan backup ke Drive',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(authStateProvider.notifier)
                              .signIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Login berhasil!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Login gagal: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Login dengan Google'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ─── Section: Backup & Restore ──────────────────
          _SectionHeader(title: 'Backup & Restore'),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup ke Google Drive'),
                  subtitle: const Text(
                      'Simpan semua data absensi ke Google Drive'),
                  enabled: isSignedIn,
                  onTap: isSignedIn
                      ? () => _handleBackup(context, ref)
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore dari Google Drive'),
                  subtitle:
                      const Text('Pulihkan data dari backup terakhir'),
                  enabled: isSignedIn,
                  onTap: isSignedIn
                      ? () => _handleRestore(context, ref)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Section: Data Lokal ────────────────────────
          _SectionHeader(title: 'Data Lokal'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.orange),
              title: const Text('Hapus Semua Data Lokal'),
              subtitle: const Text(
                  'Menghapus semua riwayat absensi, data staff, dan hutang dari perangkat'),
              onTap: () => _handleClearData(context, ref),
            ),
          ),
          
          if (isSignedIn) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Pengaturan Akun'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout dari Akun Google', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Keluar dari sesi pencadangan Google Drive'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Yakin ingin logout dari akun Google?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authStateProvider.notifier).signOut();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          _SectionHeader(title: 'Informasi'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.blue),
              title: const Text('Tentang Aplikasi'),
              subtitle: const Text('Versi dan informasi pengembang'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Officeboy Note',
                  applicationVersion: 'v1.0.0',
                  applicationIcon: const Icon(Icons.fingerprint_rounded, size: 48, color: Colors.blue),
                  applicationLegalese: '© 2026 Officeboy Note.\nAll rights reserved.',
                  children: [
                    const SizedBox(height: 16),
                    const Text('Aplikasi asisten cerdas untuk mengelola absensi, kasbon, dan pencatatan harian Anda secara terstruktur dan tersinkronisasi.'),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Pengaturan WhatsApp'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green),
              title: const Text('Template Pesan WhatsApp'),
              subtitle: const Text('Sesuaikan format rincian hutang'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pushNamed(context, '/whatsapp-settings');
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final fileName = await driveService.backup();

      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Backup berhasil!\nFile: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backup gagal: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    // Konfirmasi dulu
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Ini akan menimpa data lokal dengan data dari Google Drive. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final result = await driveService.restore();

      if (context.mounted) {
        Navigator.pop(context); // dismiss loading

        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tidak ada backup ditemukan di Google Drive'),
            ),
          );
        } else {
          // Refresh data
          ref.invalidate(attendanceProvider);
          ref.invalidate(allRecordsProvider);
          ref.invalidate(historyProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Restore berhasil!\n${result['importedCount']} record dipulihkan dari "${result['backupName']}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Restore gagal: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleClearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Lokal'),
        content: const Text(
          'Semua riwayat absensi, data staff, dan transaksi hutang akan dihapus permanen. Tindakan ini tidak bisa dibatalkan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final db = ref.read(databaseProvider);
      await db.clearAllData();

      ref.invalidate(attendanceProvider);
      ref.invalidate(allRecordsProvider);
      ref.invalidate(historyProvider);
      ref.invalidate(tasksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Semua data berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Section header widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

