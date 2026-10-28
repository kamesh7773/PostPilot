import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/media_preview.dart';
import '../models/plan_item.dart';
import '../repositories/ai_repository.dart';

/// Full preview of an autopilot slot: its media as it will look on Instagram
/// and the caption, which the user can edit until the post goes out.
class PostPreviewScreen extends HookConsumerWidget {
  final PlanItem item;

  const PostPreviewScreen({super.key, required this.item});

  static const _titles = {
    'reel': 'Reel preview',
    'image': 'Post preview',
    'carousel': 'Carousel preview',
    'story': 'Story preview',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caption = useState(item.caption);
    final editing = useState(false);
    final saving = useState(false);
    final controller = useTextEditingController(text: item.caption);
    final repo = ref.read(aiRepositoryProvider);
    final dialog = ref.read(dialogServiceProvider.notifier);
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final isStory = item.format == 'story';

    Future<void> save() async {
      final text = controller.text.trim();
      saving.value = true;
      final response = await repo.updatePlanItem(item.id, caption: text);
      if (!context.mounted) return;
      saving.value = false;
      if (!response.isSuccess) {
        dialog.showError(response.error!);
        return;
      }
      caption.value = text;
      editing.value = false;
      dialog.showSuccess('Caption updated.');
    }

    void cancel() {
      controller.text = caption.value;
      editing.value = false;
    }

    return AppScaffold(
      appBar: CustomAppBar(title: _titles[item.format] ?? 'Preview'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          MediaPreview(
            format: item.format,
            urls: item.mediaUrls,
            emptyText: item.isGenerating
                ? 'AI is still creating this. Check back in a few minutes.'
                : "The media isn't ready yet.",
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Caption', style: textTheme.titleMedium),
              const Spacer(),
              if (!isStory && item.isEditable && !editing.value)
                TextButton.icon(
                  onPressed: () => editing.value = true,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isStory)
            Text(
              "Instagram Stories don't have a caption.",
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else if (editing.value) ...[
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 6,
              maxLines: null,
              maxLength: 2200,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(hintText: 'Write a caption…'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving.value ? null : cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Save',
                    height: 44,
                    isLoading: saving.value,
                    onPressed: save,
                  ),
                ),
              ],
            ),
          ] else
            SelectableText(
              caption.value.isEmpty ? 'No caption.' : caption.value,
              style: textTheme.bodyMedium,
            ),
          if (!isStory && !item.isEditable) ...[
            const SizedBox(height: 12),
            Text(
              "This post is already publishing or posted, so its caption can't change.",
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
