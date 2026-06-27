import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/recent_activity_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(recentActivityProvider);
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
    final isRefreshing = activityState.isLoading || activityState.isRefreshing;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Putih susu seragam
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, selamat datang!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beranda',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 1.0,
                        ),
                  ),
                ],
              ),
            ),
            
            // Menu Grid (3 Kolom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 0.85, 
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MenuIcon(
                    title: 'Absensi',
                    icon: Icons.fingerprint_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, '/attendance');
                    },
                  ),
                  _MenuIcon(
                    title: 'Staff List',
                    icon: Icons.people_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, '/staff');
                    },
                  ),
                  _MenuIcon(
                    title: 'Titipan',
                    icon: Icons.assignment_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, '/tasks');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Recent Activity Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Terbaru',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  isRefreshing
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                          onPressed: () => ref.invalidate(recentActivityProvider),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Recent Activity List (Scrollable)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(recentActivityProvider);
                },
                child: activityState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Gagal memuat aktivitas: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Belum ada aktivitas tercatat',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withAlpha(10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: item.color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: item.color),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                dateFormat.format(item.timestamp),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuIcon({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white, // Kartu tombol putih bersih
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16), // Padding diperkecil agar pas 3 kolom
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withAlpha(10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 36, // Icon diperkecil sedikit
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13, // Font diperkecil sedikit
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
