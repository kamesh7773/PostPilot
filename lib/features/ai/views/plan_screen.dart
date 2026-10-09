import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/plan_item.dart';
import '../repositories/ai_repository.dart';

/// AI weekly timeline: what to post and when. The user only adds the media
/// for each slot; caption, type and time are filled in on Create post.
class PlanScreen extends HookConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = useState<List<PlanItem>?>(null);
    final planning = useState(false);
    final repo = ref.read(aiRepositoryProvider);
    final dialog = ref.read(dialogServiceProvider.notifier);

    Future<void> load() async {
      final response = await repo.fetchPlan();
      if (!context.mounted) return;
      if (response.isSuccess) {
        items.value = response.data;
      } else {
        items.value ??= const [];
        dialog.showError(response.error!);
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    Future<void> plan() async {
      planning.value = true;
      final now = DateTime.now();
      // Start tomorrow so no slot lands in the past.
      final response = await repo.generatePlan(
        DateTime(now.year, now.month, now.day + 1),
      );
      if (!context.mounted) return;
      planning.value = false;
      if (response.isSuccess) {
        await load();
      } else {
        dialog.showError(
          response.statusCode == 409
              ? 'Set up your creator profile first.'
              : response.error!,
        );
      }
    }

    Future<void> fill(PlanItem item) async {
      await ref
          .read(navigationServiceProvider.notifier)
          .pushNamed(Routes.compose, arguments: item);
      await load();
    }

    Future<void> remove(PlanItem item) async {
      items.value = [...?items.value]..remove(item);
      final response = await repo.deletePlanItem(item.id);
      if (!response.isSuccess) await load();
    }

    final list = items.value;
    final byDay = <DateTime, List<PlanItem>>{};
    for (final item in list ?? const <PlanItem>[]) {
      final t = item.when;
      (byDay[DateTime(t.year, t.month, t.day)] ??= []).add(item);
    }

    return AppScaffold(
      appBar: const CustomAppBar(title: 'Your week'),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _PlanHeader(
                    hasPlan: list.isNotEmpty,
                    planning: planning.value,
                    onPlan: plan,
                  ),
                  for (final day in byDay.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
                      child: Text(
                        formatPostDay(context, day.key),
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    for (final item in day.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SlotCard(
                          item: item,
                          onFill: () => fill(item),
                          onRemove: () => remove(item),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final bool hasPlan;
  final bool planning;
  final VoidCallback onPlan;

  const _PlanHeader({
    required this.hasPlan,
    required this.planning,
    required this.onPlan,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPlan ? 'Your AI plan ✨' : 'Let AI plan your week ✨',
            style: textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            planning
                ? 'Planning your week… this can take a couple of minutes.'
                : hasPlan
                ? 'Add a photo or video to each slot. Caption, type and time '
                      'are ready. Re-planning keeps slots you already filled.'
                : 'Get a timeline of Reels, posts and Stories with times and '
                      'captions. You just add the media.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: hasPlan ? 'Re-plan my week' : 'Plan my week',
            icon: Icons.auto_awesome,
            isLoading: planning,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: onPlan,
          ),
          const SizedBox(height: 10),
          Text(
            'Ideas to test, not guarantees of reach.',
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final PlanItem item;
  final VoidCallback onFill;
  final VoidCallback onRemove;

  const _SlotCard({
    required this.item,
    required this.onFill,
    required this.onRemove,
  });

  static const _formats = {
    'reel': ('Reel', Icons.movie_outlined, 'Add video'),
    'image': ('Photo', Icons.image_outlined, 'Add photo'),
    'carousel': ('Carousel', Icons.collections_outlined, 'Add photos'),
    'story': ('Story', Icons.amp_stories_outlined, 'Add photo or video'),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final (label, icon, action) = _formats[item.format] ?? _formats['image']!;
    final passed = !item.isFilled && item.when.isBefore(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formatPostTimeOfDay(context, item.when),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                _Pill(
                  icon: icon,
                  text: label,
                  color: colors.primary,
                  background: colors.primaryContainer,
                ),
                const Spacer(),
                if (item.isFilled)
                  _Pill(
                    icon: Icons.check_circle,
                    text: switch (item.postStatus) {
                      'published' => 'Posted',
                      'failed' => 'Failed',
                      _ => 'Scheduled',
                    },
                    color: item.postStatus == 'failed'
                        ? AppColors.error
                        : AppColors.success,
                    background:
                        (item.postStatus == 'failed'
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: 0.12),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Remove slot',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: textTheme.titleMedium),
                  if (item.hook.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${item.hook}”',
                      style: textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (item.why.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.why,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!item.isFilled) ...[
                    const SizedBox(height: 14),
                    CustomButton(
                      text: passed ? '$action and post now' : action,
                      icon: Icons.add_rounded,
                      height: 44,
                      onPressed: onFill,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
