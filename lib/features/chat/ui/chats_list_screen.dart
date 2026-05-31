import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer.dart';

/// The Chats tab: every document the user has started a conversation with,
/// most recent first.
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: SafeArea(
        child: chatsAsync.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorView(
            message: "We couldn't load your conversations.",
            onRetry: () => ref.invalidate(chatsStreamProvider),
          ),
          data: (chats) {
            if (chats.isEmpty) {
              return const EmptyState(
                icon: Symbols.forum,
                title: 'No conversations yet',
                message:
                    'Open a summarized document and tap "Ask questions" to '
                    'start chatting with it.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: chats.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (_, i) {
                final c = chats[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    leading: CircleAvatar(
                      backgroundColor:
                          context.colors.secondaryContainer.withValues(alpha: 0.4),
                      child: Icon(Symbols.auto_awesome,
                          fill: 1, color: context.colors.secondary),
                    ),
                    title: Text(c.documentName,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        c.lastMessage.isEmpty ? 'Tap to continue' : c.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: Text(c.updatedAt.relative,
                        style: context.text.labelSmall),
                    onTap: () => context.push('/chat/${c.documentId}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
