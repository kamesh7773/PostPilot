import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/api_response.dart';
import '../../../core/services/supabase_client.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository._(ref.watch(supabaseClientProvider).auth);

/// Supabase auth events (signedIn, signedOut, tokenRefreshed, ...).
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

/// Wraps Supabase Auth. Sessions are persisted and refreshed by
/// `supabase_flutter`, so nothing here touches secure storage.
class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository._(this._auth);

  bool get isSignedIn => _auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<ApiResponse<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return ApiResponse.success(response.user!);
    } on AuthException catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      debugPrint('AuthRepository.signIn: $e');
      return ApiResponse.failure('Unable to sign in. Please try again.');
    }
  }

  /// On success, `data` is `true` when Supabase requires the user to
  /// confirm their email before a session is issued.
  Future<ApiResponse<bool>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      return ApiResponse.success(response.session == null);
    } on AuthException catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      debugPrint('AuthRepository.signUp: $e');
      return ApiResponse.failure('Unable to create account. Please try again.');
    }
  }

  Future<void> signOut() => _auth.signOut();
}
