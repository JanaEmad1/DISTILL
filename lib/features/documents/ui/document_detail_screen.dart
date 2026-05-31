import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/ai_badge.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../data/models/document_model.dart';
import '../data/share_text.dart';

/// Tabbed document view: AI Summary, Key Points, and the original extracted
/// text. Anchored by an "Ask questions" CTA that opens the document chat.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentByIdProvider(documentId));

    return Scaffold(
      body: docAsync.when(
        loading: () => const SafeArea(child: _DetailSkeleton()),
        error: (e, _) => SafeArea(
          child: ErrorView(
            message: "We couldn't open this document.",
            onRetry: () => ref.invalidate(documentByIdProvider(documentId)),
          ),
        ),
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('Document not found.'));
          }
          return _Loaded(doc: doc);
        },
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.doc});
  final DocumentModel doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: [
            _Header(doc: doc),
            TabBar(
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Key Points'),
                Tab(text: 'Original'),
              ],
              labelStyle: context.text.titleSmall,
              indicatorColor: context.colors.primary,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(doc: doc),
                  _KeyPointsTab(doc: doc),
                  _OriginalTab(doc: doc),
                ],
              ),
            ),
            if (doc.isReady)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/chat/${doc.id}'),
                    icon: const Icon(Symbols.chat_bubble, fill: 1),
                    label: const Text('Ask questions about this'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.doc});
  final DocumentModel doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const Spacer(),
              if (doc.isReady) ...[
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Symbols.content_copy),
                  onPressed: () => _copy(context),
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Symbols.share),
                  onPressed: () => _share(context),
                ),
              ],
              IconButton(
                icon: Icon(doc.favorite ? Symbols.star : Symbols.star,
                    fill: doc.favorite ? 1 : 0,
                    color: doc.favorite ? context.colors.secondary : null),
                onPressed: () => ref
                    .read(documentRepositoryProvider)
                    ?.toggleFavorite(doc.id, !doc.favorite),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name,
                    style: context.text.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${doc.type.toUpperCase()} · ${doc.sizeBytes.readableSize}'
                  '${doc.pages > 0 ? ' · ${doc.pages} pages' : ''}',
                  style: context.text.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: buildShareText(doc)));
    if (context.mounted) context.showSnack('Copied to clipboard');
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(ShareParams(text: buildShareText(doc)));
    } catch (_) {
      if (context.mounted) {
        context.showSnack("Couldn't open the share sheet.", isError: true);
      }
    }
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.doc});
  final DocumentModel doc;

  @override
  Widget build(BuildContext context) {
    if (!doc.isReady) return _Pending(status: doc.status);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const AiBadge(label: 'AI Summary'),
        const SizedBox(height: AppSpacing.md),
        Text(
          doc.summary ?? 'No summary available.',
          style: context.text.bodyLarge?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _KeyPointsTab extends StatelessWidget {
  const _KeyPointsTab({required this.doc});
  final DocumentModel doc;

  @override
  Widget build(BuildContext context) {
    if (!doc.isReady) return _Pending(status: doc.status);
    if (doc.keyPoints.isEmpty) {
      return Center(
        child: Text('No key points extracted.',
            style: context.text.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: doc.keyPoints.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.check_circle,
              fill: 1, size: 20, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(doc.keyPoints[i],
                style: context.text.bodyLarge?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _OriginalTab extends StatelessWidget {
  const _OriginalTab({required this.doc});
  final DocumentModel doc;

  @override
  Widget build(BuildContext context) {
    final text = doc.extractedText.trim();
    if (text.isEmpty) {
      return Center(
        child: Text('Original text is not available.',
            style: context.text.bodyMedium),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SelectableText(text,
            style: context.text.bodyMedium?.copyWith(height: 1.6)),
      ],
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.status});
  final DocStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(height: AppSpacing.lg),
          Text(status.label, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

/// Shimmering placeholder shown while the document loads: a header block, then
/// a few paragraph lines mimicking the summary.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SkeletonBox(width: 240, height: 24),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 150, height: 12),
          const SizedBox(height: AppSpacing.xxl),
          const SkeletonBox(width: 120, height: 16),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 8; i++) ...[
            SkeletonBox(width: i.isEven ? double.infinity : 260, height: 12),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
