import 'package:flutter/foundation.dart';

import '../models/social_account.dart';

@immutable
class SocialAccountsState {
  final List<SocialAccount> accounts;
  final bool isLoading;
  final bool isConnecting;
  final String? error;

  const SocialAccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.isConnecting = false,
    this.error,
  });

  static const _sentinel = Object();

  SocialAccountsState copyWith({
    List<SocialAccount>? accounts,
    bool? isLoading,
    bool? isConnecting,
    Object? error = _sentinel,
  }) => SocialAccountsState(
    accounts: accounts ?? this.accounts,
    isLoading: isLoading ?? this.isLoading,
    isConnecting: isConnecting ?? this.isConnecting,
    error: error == _sentinel ? this.error : error as String?,
  );
}
