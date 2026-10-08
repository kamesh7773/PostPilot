import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_response.dart';
import '../models/app_user.dart';
import '../repositories/home_repository.dart';

part 'home_view_model.g.dart';

/// The backend profile for the signed-in user. Refresh with
/// `ref.invalidate(currentUserProvider)`.
@riverpod
Future<ApiResponse<AppUser>> currentUser(Ref ref) =>
    ref.watch(homeRepositoryProvider).fetchMe();
