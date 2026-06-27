import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service for Google Sign-In authentication.
class GoogleAuthService {
  static const _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  final GoogleSignIn _googleSignIn;

  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(
          scopes: _scopes,
          // Web client ID — ganti dengan punya kamu dari Google Cloud Console
          // serverClientId: null, // di-set null untuk web-only OAuth
        );

  /// Get the current signed-in user (null if not signed in).
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Whether the user is signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Stream of sign-in state changes.
  Stream<GoogleSignInAccount?> get onUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Sign in with Google.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      if (kIsWeb) {
        // Web flow: explicitly request scopes
        return await _googleSignIn.signIn();
      }
      return await _googleSignIn.signIn();
    } catch (e) {
      // ignore: avoid_print
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get auth headers for Google Drive API calls.
  Future<Map<String, String>> getAuthHeaders() async {
    final auth = await _googleSignIn.currentUser?.authentication;
    if (auth == null) {
      throw Exception('User not signed in');
    }
    return {
      'Authorization': 'Bearer ${auth.accessToken}',
    };
  }
}
