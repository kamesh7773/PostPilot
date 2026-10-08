import 'package:flutter/foundation.dart';

@immutable
class AuthViewState {
  final bool isLoading;

  const AuthViewState({this.isLoading = false});

  AuthViewState copyWith({bool? isLoading}) =>
      AuthViewState(isLoading: isLoading ?? this.isLoading);
}
