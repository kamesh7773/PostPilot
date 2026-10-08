import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/dialog_service.dart';
import '../repositories/social_accounts_repository.dart';
import 'social_accounts_state.dart';

part 'social_accounts_view_model.g.dart';

@riverpod
class SocialAccountsViewModel extends _$SocialAccountsViewModel {
  @override
  SocialAccountsState build() {
    Future.microtask(load);
    return const SocialAccountsState(isLoading: true);
  }

  SocialAccountsRepository get _repo =>
      ref.read(socialAccountsRepositoryProvider);
  DialogService get _dialog => ref.read(dialogServiceProvider.notifier);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await _repo.fetchAccounts();
    if (!ref.mounted) return;

    state = response.isSuccess
        ? state.copyWith(accounts: response.data, isLoading: false)
        : state.copyWith(isLoading: false, error: response.error);
  }

  /// Opens Facebook Login in a secure browser sheet. The backend finishes
  /// the OAuth exchange and redirects to `postpilot://oauth/instagram`.
  Future<void> connectInstagram() async {
    if (state.isConnecting) return;
    state = state.copyWith(isConnecting: true);

    try {
      final start = await _repo.startInstagramConnect();
      if (!start.isSuccess) {
        _dialog.showError(start.error!);
        return;
      }

      final result = await FlutterWebAuth2.authenticate(
        url: start.data!,
        callbackUrlScheme: AppConstants.oauthCallbackScheme,
      );
      final params = Uri.parse(result).queryParameters;

      switch (params['status']) {
        case 'success':
          final count = int.tryParse(params['count'] ?? '') ?? 1;
          _dialog.showSuccess(
            count == 1
                ? 'Instagram account connected.'
                : '$count Instagram accounts connected.',
          );
          await load();
        case 'cancelled':
          break;
        default:
          _dialog.showError(
            params['message'] ?? 'Could not connect Instagram.',
          );
      }
    } on PlatformException catch (e) {
      // CANCELED: the user closed the browser sheet.
      if (e.code != 'CANCELED') {
        _dialog.showError(e.message ?? 'Could not open Instagram login.');
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isConnecting: false);
    }
  }

  Future<void> disconnect(String id) async {
    final response = await _repo.disconnect(id);
    if (!ref.mounted) return;

    if (response.isSuccess) {
      state = state.copyWith(
        accounts: state.accounts
            .where((a) => a.id != id)
            .toList(growable: false),
      );
      _dialog.showSuccess('Account disconnected.');
    } else {
      _dialog.showError(response.error ?? 'Could not disconnect account.');
    }
  }
}
