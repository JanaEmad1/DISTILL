import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';

/// App settings: appearance (theme mode) and backend status. Theme choice is
/// persisted via [ThemeController].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionLabel('Appearance'),
            Card(
              child: RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (m) => m == null
                    ? null
                    : ref.read(themeControllerProvider.notifier).set(m),
                child: const Column(
                  children: [
                    _ThemeOption(
                      label: 'System default',
                      icon: Symbols.brightness_auto,
                      value: ThemeMode.system,
                    ),
                    _ThemeOption(
                      label: 'Light',
                      icon: Symbols.light_mode,
                      value: ThemeMode.light,
                    ),
                    _ThemeOption(
                      label: 'Dark',
                      icon: Symbols.dark_mode,
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel('About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.info),
                    title: const Text('Version'),
                    trailing: Text('1.0.0', style: context.text.labelMedium),
                  ),
                  ListTile(
                    leading: Icon(
                      firebaseReady ? Symbols.cloud_done : Symbols.cloud_off,
                      color: firebaseReady
                          ? context.colors.secondary
                          : context.colors.onSurfaceVariant,
                    ),
                    title: const Text('Backend'),
                    subtitle: Text(firebaseReady
                        ? 'Connected to Firebase'
                        : 'Demo mode (offline sample data)'),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.auto_awesome),
                    title: const Text('AI'),
                    subtitle: Text(firebaseReady
                        ? 'Gemini via Firebase AI Logic'
                        : 'Stubbed responses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConstants.tagline,
                textAlign: TextAlign.center,
                style: context.text.labelMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(text.toUpperCase(),
          style: context.text.labelMedium?.copyWith(letterSpacing: 0.8)),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.value,
  });
  final String label;
  final IconData icon;
  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      secondary: Icon(icon),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
