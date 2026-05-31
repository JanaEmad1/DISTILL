import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/data/models/app_user.dart';
import '../../auth/logic/auth_controller.dart';

/// The Profile tab: identity, usage stats, account actions, and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final docs =
        ref.watch(documentsStreamProvider).value ?? const [];
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final storage = docs.fold<int>(0, (sum, d) => sum + d.sizeBytes);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: AppSpacing.xl),
            _StatsRow(
              docCount: docs.length,
              questionCount: user.questionCount,
              storageBytes: storage,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTile(
              icon: Symbols.edit,
              label: 'Edit profile',
              onTap: () => context.push('/edit-profile'),
            ),
            _SectionTile(
              icon: Symbols.settings,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _SectionTile(
              icon: Symbols.workspace_premium,
              label: 'Subscription',
              trailing: Text(user.subscription,
                  style: context.text.labelMedium
                      ?.copyWith(color: context.colors.secondary)),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: Icon(Symbols.logout, color: context.colors.error),
              label: Text('Sign out',
                  style: TextStyle(color: context.colors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: context.colors.secondaryContainer,
          child: Text(user.initial,
              style: context.text.displaySmall
                  ?.copyWith(color: context.colors.onSecondaryContainer)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(user.displayName ?? 'Distill user',
            style: context.text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(user.email, style: context.text.bodyMedium),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.docCount,
    required this.questionCount,
    required this.storageBytes,
  });
  final int docCount;
  final int questionCount;
  final int storageBytes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(value: '$docCount', label: 'Documents'),
            _Stat(value: '$questionCount', label: 'Questions'),
            _Stat(value: storageBytes.readableSize, label: 'Storage'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: context.text.headlineSmall
                ?.copyWith(color: context.colors.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: context.text.labelMedium),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.colors.onSurfaceVariant),
      title: Text(label, style: context.text.titleSmall),
      trailing: trailing ??
          (onTap != null ? const Icon(Symbols.chevron_right) : null),
      onTap: onTap,
    );
  }
}
