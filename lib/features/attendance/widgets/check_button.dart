import 'package:flutter/material.dart';

/// Tombol utama check-in / check-out.
/// Hijau = siap check-in (Masuk), Merah = siap check-out (Keluar).
class CheckButton extends StatelessWidget {
  final bool isCheckedIn;
  final bool isLoading;
  final bool isCompleted;
  final bool isTooEarly;
  final VoidCallback onPressed;

  const CheckButton({
    super.key,
    required this.isCheckedIn,
    required this.isLoading,
    this.isCompleted = false,
    this.isTooEarly = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = isCompleted || isTooEarly;
    
    final gradient = isLocked 
        ? const LinearGradient(
            colors: [Colors.grey, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (isCheckedIn
            ? const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ));

    final shadowColor = isLocked ? Colors.transparent : (isCheckedIn ? Colors.redAccent : Colors.greenAccent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withAlpha(120),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocked 
                            ? (isCompleted ? Icons.check_circle_rounded : Icons.access_time_filled_rounded)
                            : (isCheckedIn ? Icons.logout_rounded : Icons.login_rounded),
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLocked
                            ? (isCompleted ? 'Selesai' : 'Belum Jam 6')
                            : (isCheckedIn ? 'Keluar' : 'Masuk'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
