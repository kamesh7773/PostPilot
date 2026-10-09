import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/dialog_service.dart';
import '../models/creator_profile.dart';
import '../repositories/profile_repository.dart';

part 'profile_view_model.g.dart';

/// The creator profile; `null` until onboarding is completed.
@Riverpod(keepAlive: true)
class ProfileViewModel extends _$ProfileViewModel {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<CreatorProfile?> build() async {
    final response = await _repo.fetch();
    if (!response.isSuccess) throw Exception(response.error);
    return response.data;
  }

  /// Returns true on success.
  Future<bool> save(CreatorProfile profile) async {
    final response = await _repo.save(profile);
    if (!ref.mounted) return false;
    if (!response.isSuccess) {
      ref.read(dialogServiceProvider.notifier).showError(response.error!);
      return false;
    }
    state = AsyncData(response.data);
    return true;
  }
}
