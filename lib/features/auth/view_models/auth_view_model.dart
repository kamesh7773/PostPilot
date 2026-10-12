import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/dialog_service.dart';
import '../../../core/services/push_service.dart';
import '../repositories/auth_repository.dart';
import 'auth_state.dart';

part 'auth_view_model.g.dart';

/// Sign in / sign up / sign out.
///
/// Navigation is not done here: `PostPilotApp` listens to Supabase auth
/// events and routes to Home on sign-in and to Login on sign-out.
@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  AuthViewState build() => const AuthViewState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  DialogService get _dialog => ref.read(dialogServiceProvider.notifier);

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repo.signIn(email: email, password: password);
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false);

    if (!response.isSuccess) {
      _dialog.showError(response.error!);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repo.signUp(email: email, password: password);
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false);

    if (!response.isSuccess) {
      _dialog.showError(response.error!);
    } else if (response.data == true) {
      _dialog.showInfo(
        'Check your inbox to confirm your email, then sign in.',
        title: 'Confirm your email',
      );
    }
  }

  Future<void> signOut() async {
    // Read before awaiting: nothing watches this provider on Home, so it can
    // be disposed while unregister() is in flight.
    final repo = _repo;
    await ref.read(pushServiceProvider.notifier).unregister();
    await repo.signOut();
  }
}
