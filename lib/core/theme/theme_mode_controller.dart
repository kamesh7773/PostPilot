import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/storage_service.dart';

part 'theme_mode_controller.g.dart';

/// The user's System / Light / Dark choice, saved on the device.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  // ponytail: loads async, so a saved Light/Dark can flash System for a frame
  // at launch (hidden by the splash). Preload prefs in main() if it shows.
  Future<void> _load() async {
    final saved = await ref
        .read(storageServiceProvider.notifier)
        .getString(_key);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(storageServiceProvider.notifier).setString(_key, mode.name);
  }
}
