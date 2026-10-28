import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../models/brand.dart';
import '../repositories/brands_repository.dart';
import 'brand_screen.dart';

/// Live QR posts (dev flavor only). The backend makes the Live QR brand, brief included,
/// on first visit, so this goes straight to it.
class BrandsScreen extends HookConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = useState<Brand?>(null);
    final error = useState<String?>(null);
    final repo = ref.read(brandsRepositoryProvider);

    Future<void> load() async {
      error.value = null;
      final response = await repo.fetchBrands();
      if (!context.mounted) return;
      if (response.isSuccess && response.data!.isNotEmpty) {
        brand.value = response.data!.first;
      } else {
        error.value = response.error ?? 'Couldn\'t open Live QR posts.';
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    if (brand.value != null) return BrandScreen(initial: brand.value!);
    return AppScaffold(
      appBar: const CustomAppBar(title: 'Live QR posts'),
      body: Center(
        child: error.value == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.value!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: load, child: const Text('Try again')),
                ],
              ),
      ),
    );
  }
}
