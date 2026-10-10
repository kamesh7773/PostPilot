import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/plan_item.dart';
import '../repositories/ai_repository.dart';

/// AI weekly timeline on autopilot: AI makes and posts every slot. The user
/// can only change times, retry a failed slot, or remove one.
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

    // Refresh while the autopilot is making media, so slots flip to Scheduled.
    final generating = items.value?.any((i) => i.isGenerating) ?? false;
    useEffect(() {
      if (!generating) return null;
      final timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
      return timer.cancel;
    }, [generating]);

    final list = items.value;

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

    Future<void> editTime(PlanItem item) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(item.when),
      );
      if (picked == null || !context.mounted) return;
      String two(int n) => n.toString().padLeft(2, '0');
      final response = await repo.updatePlanItem(
        item.id,
        time: '${two(picked.hour)}:${two(picked.minute)}',
      );
      if (!context.mounted) return;
      if (!response.isSuccess) dialog.showError(response.error!);
      await load();
    }

    Future<void> retry(PlanItem item) async {
      final response = await repo.updatePlanItem(item.id, retry: true);
      if (!context.mounted) return;
      if (!response.isSuccess) dialog.showError(response.error!);
      await load();
    }

    Future<void> remove(PlanItem item) async {
      items.value = [...?items.value]..remove(item);
      final response = await repo.deletePlanItem(item.id);
      if (!response.isSuccess) await load();
    }

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
                children: Reveal.stagger([
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
                          onRemove: () => remove(item),
                          onEditTime: () => editTime(item),
                          onRetry: () => retry(item),
                        ),
                      ),
                  ],
                ]),
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
    return AuroraCard(
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
                : 'AI creates every Reel, post, carousel and Story and posts '
                      'them on time. You can change the times. You get a '
                      'notification when each one goes live.',
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
  final VoidCallback onRemove;
  final VoidCallback onEditTime;
  final VoidCallback onRetry;

  const _SlotCard({
    required this.item,
    required this.onRemove,
    required this.onEditTime,
    required this.onRetry,
  });

  static const _formats = {
    'reel': ('Reel', Icons.movie_outlined),
    'image': ('Post', Icons.image_outlined),
    'carousel': ('Carousel', Icons.collections_outlined),
    'story': ('Story', Icons.amp_stories_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final (label, icon) = _formats[item.format] ?? _formats['image']!;
    final timeEditable =
        item.postStatus == null || item.postStatus == 'scheduled';

    return PulseGlow(
      active: item.isGenerating,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time is editable until the post starts publishing.
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: timeEditable ? onEditTime : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatPostTimeOfDay(context, item.when),
                            style: textTheme.titleMedium,
                          ),
                          if (timeEditable) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: colors.onSurfaceVariant,
                              semanticLabel: 'Change time',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Pill(
                    icon: icon,
                    text: label,
                    color: colors.primary,
                    background: colors.primaryContainer,
                  ),
                  const Spacer(),
                  if (item.isGenerating)
                    _Pill(
                      icon: Icons.auto_awesome,
                      text: 'AI creating',
                      color: colors.primary,
                      background: colors.primaryContainer,
                    )
                  else if (item.isFilled)
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
                    if (item.mediaUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.mediaUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    if (item.isGenerating) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.format == 'reel'
                                  ? 'Creating your Reel. Videos take a few minutes.'
                                  : 'Creating your $label.',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.autoStatus == 'failed' &&
                        item.autoError != null &&
                        !item.isFilled) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.autoError!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    // Autopilot slots never take media from the user; a failed
                    // one can only be retried (or moved to a later time).
                    // A failed slot can only be retried (or moved to a later time).
                    if (item.autoStatus == 'failed' && !item.isFilled) ...[
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Try again',
                        icon: Icons.refresh_rounded,
                        height: 44,
                        onPressed: onRetry,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
