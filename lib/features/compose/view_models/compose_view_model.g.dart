// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ComposeViewModel)
final composeViewModelProvider = ComposeViewModelProvider._();

final class ComposeViewModelProvider
    extends $NotifierProvider<ComposeViewModel, ComposeState> {
  ComposeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'composeViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$composeViewModelHash();

  @$internal
  @override
  ComposeViewModel create() => ComposeViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComposeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComposeState>(value),
    );
  }
}

String _$composeViewModelHash() => r'6ab6053faf7a425f0d5b8c815ffd1388a61ee6cc';

abstract class _$ComposeViewModel extends $Notifier<ComposeState> {
  ComposeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ComposeState, ComposeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ComposeState, ComposeState>,
              ComposeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
