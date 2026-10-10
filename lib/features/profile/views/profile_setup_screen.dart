import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/creator_profile.dart';
import '../view_models/profile_view_model.dart';

const _niches = [
  'Fitness',
  'Health',
  'Medical',
  'Food',
  'Travel',
  'Fashion',
  'Tech',
  'Education',
  'Finance',
  'Comedy',
];
const _ageGroups = ['13-17', '18-24', '25-34', '35-44', '45+'];
const _countries = ['India', 'USA', 'UK', 'UAE', 'Canada', 'Australia'];
const _formats = {
  'reel': 'Reels',
  'image': 'Photos',
  'carousel': 'Carousels',
  'story': 'Stories',
};
const _languages = ['English', 'Hindi', 'Hinglish'];
const _tones = [
  'friendly',
  'professional',
  'funny',
  'motivational',
  'educational',
];

/// The onboarding questions. Also used to edit the profile later.
class ProfileSetupScreen extends HookConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(profileViewModelProvider).value;

    final niche = useTextEditingController(text: existing?.niche ?? '');
    final otherCountry = useTextEditingController();
    final ageGroup = useState(existing?.audienceAgeGroup ?? '18-24');
    final countries = useState<Set<String>>({...?existing?.targetCountries});
    final formats = useState<Set<String>>({...?existing?.preferredFormats});
    final language = useState(existing?.language ?? 'English');
    final tone = useState(existing?.tone ?? 'friendly');
    final saving = useState(false);
    useListenable(niche);

    final canSave =
        niche.text.trim().length >= 2 &&
        (countries.value.isNotEmpty || otherCountry.text.trim().isNotEmpty) &&
        formats.value.isNotEmpty &&
        !saving.value;

    Future<void> save() async {
      saving.value = true;
      final extra = otherCountry.text.trim();
      final ok = await ref
          .read(profileViewModelProvider.notifier)
          .save(
            CreatorProfile(
              niche: niche.text.trim(),
              audienceAgeGroup: ageGroup.value,
              targetCountries: [
                ...countries.value,
                if (extra.isNotEmpty) extra,
              ],
              preferredFormats: formats.value.toList(),
              language: language.value,
              tone: tone.value,
            ),
          );
      if (!context.mounted) return;
      saving.value = false;
      if (ok) ref.read(navigationServiceProvider.notifier).pop();
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );

    return AppScaffold(
      appBar: CustomAppBar(
        title: existing == null ? 'Tell us about you' : 'Creator profile',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: Reveal.stagger([
          Text(
            'Autocreator uses these answers to suggest what to post, when, and how to write it.',
            style: TextStyle(color: context.colorScheme.onSurfaceVariant),
          ),
          section('What do you post about?'),
          TextField(
            controller: niche,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. fitness, health, medical, food',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in _niches)
                ChoiceChip(
                  label: Text(n),
                  // Matches typed text too, so a saved "fitness" shows Fitness.
                  selected: niche.text.trim().toLowerCase() == n.toLowerCase(),
                  onSelected: (_) => niche.text = n,
                ),
            ],
          ),
          section('Audience age group'),
          Wrap(
            spacing: 8,
            children: [
              for (final a in _ageGroups)
                ChoiceChip(
                  label: Text(a),
                  selected: ageGroup.value == a,
                  onSelected: (_) => ageGroup.value = a,
                ),
            ],
          ),
          section('Target countries'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _countries)
                FilterChip(
                  label: Text(c),
                  selected: countries.value.contains(c),
                  onSelected: (on) => countries.value = on
                      ? {...countries.value, c}
                      : ({...countries.value}..remove(c)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: otherCountry,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Another country (optional)',
            ),
          ),
          section('What do you mostly post?'),
          Wrap(
            spacing: 8,
            children: [
              for (final f in _formats.entries)
                FilterChip(
                  label: Text(f.value),
                  selected: formats.value.contains(f.key),
                  onSelected: (on) => formats.value = on
                      ? {...formats.value, f.key}
                      : ({...formats.value}..remove(f.key)),
                ),
            ],
          ),
          section('Caption language'),
          Wrap(
            spacing: 8,
            children: [
              for (final l in _languages)
                ChoiceChip(
                  label: Text(l),
                  selected: language.value == l,
                  onSelected: (_) => language.value = l,
                ),
            ],
          ),
          section('Tone'),
          Wrap(
            spacing: 8,
            children: [
              for (final t in _tones)
                ChoiceChip(
                  label: Text(t),
                  selected: tone.value == t,
                  onSelected: (_) => tone.value = t,
                ),
            ],
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: 'Save',
            isLoading: saving.value,
            onPressed: canSave ? save : null,
          ),
        ]),
      ),
    );
  }
}
