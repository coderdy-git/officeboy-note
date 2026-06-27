import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/google_auth_service.dart';
import '../../../core/backup/google_drive_service.dart';
import '../../attendance/providers/attendance_provider.dart';

/// Provider untuk GoogleAuthService singleton.
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Provider untuk GoogleDriveService.
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final auth = ref.watch(googleAuthServiceProvider);
  final db = ref.watch(databaseProvider);
  return GoogleDriveService(auth, db);
});

/// Provider untuk state autentikasi Google.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, GoogleSignInAccount?>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return AuthNotifier(authService);
});

/// Provider untuk status login (agar mudah digunakan).
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) != null;
});

class AuthNotifier extends StateNotifier<GoogleSignInAccount?> {
  final GoogleAuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser) {
    _authService.onUserChanged.listen((account) {
      state = account;
    });
  }

  Future<void> signIn() async {
    final account = await _authService.signIn();
    state = account;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }
}
