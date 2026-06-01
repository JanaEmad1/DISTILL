import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../data/models/document_model.dart';
import '../logic/upload_controller.dart';
import 'widgets/document_card.dart';
import 'widgets/upload_sheet.dart';

enum _Filter { all, recent, favorites, pdfs }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DocumentModel> _apply(List<DocumentModel> docs) {
    var list = docs;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((d) => d.name.toLowerCase().contains(q)).toList();
    }
    switch (_filter) {
      case _Filter.favorites:
        list = list.where((d) => d.favorite).toList();
      case _Filter.pdfs:
        list = list.where((d) => d.type == 'pdf').toList();
      case _Filter.recent:
        list = [...list]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _Filter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final docsAsync = ref.watch(documentsStreamProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startUpload,
        icon: const Icon(Symbols.add),
        label: const Text('Upload'),
      ),
      body: SafeArea(
        child: docsAsync.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorView(
            message: "We couldn't load your documents.",
            onRetry: () => ref.invalidate(documentsStreamProvider),
          ),
          data: (allDocs) {
            final docs = _apply(allDocs);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context, user?.displayName)),
                SliverToBoxAdapter(child: _searchBar()),
                SliverToBoxAdapter(child: _filterChips()),
                SliverToBoxAdapter(child: _sectionHeader(context)),
                if (allDocs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Symbols.docs,
                      title: 'No documents yet',
                      message:
                          'Upload your first PDF, Word, or text file to get an '
                          'instant AI summary.',
                      actionLabel: 'Upload document',
                      onAction: _startUpload,
                    ),
                  )
                else if (docs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Symbols.search_off,
                      title: 'No matches',
                      message: 'Try a different search or filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, 96),
                    sliver: SliverList.separated(
                      itemCount: docs.length,
                      itemBuilder: (_, i) => DocumentCard(
                        doc: docs[i],
                        onTap: () => _open(docs[i]),
                        onMore: () => _showActions(docs[i]),
                      ),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.gutter),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _open(DocumentModel doc) {
    if (doc.status.isProcessing) {
      context.push('/processing/${doc.id}');
    } else {
      context.push('/document/${doc.id}');
    }
  }

  /// Opens the system file picker directly; on selection, shows a confirmation
  /// sheet, then starts processing. Cancelling the picker simply returns here —
  /// no dead-end screen.
  Future<void> _startUpload() async {
    final notifier = ref.read(uploadControllerProvider.notifier);
    await notifier.pick();
    if (!mounted) return;

    final state = ref.read(uploadControllerProvider);
    if (state.hasError) {
      context.showSnack(state.error.toString(), isError: true);
      notifier.clear();
      return;
    }

    final picked = state.value;
    if (picked == null) {
      // Cancelled the OS picker (e.g. backed out of an empty folder).
      context.showSnack('No file selected');
      return;
    }

    final confirmed = await showUploadConfirmSheet(context, picked);
    if (!mounted) return;
    if (confirmed == true) {
      final id = await notifier.startUpload();
      if (id != null && mounted) context.push('/processing/$id');
    } else {
      notifier.clear();
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showActions(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(doc.favorite ? Symbols.star_outline : Symbols.star),
              title: Text(doc.favorite
                  ? 'Remove from favorites'
                  : 'Add to favorites'),
              onTap: () {
                ref
                    .read(documentRepositoryProvider)
                    ?.toggleFavorite(doc.id, !doc.favorite);
                Navigator.pop(context);
              },
            ),
            if (doc.isReady)
              ListTile(
                leading: const Icon(Symbols.chat_bubble),
                title: const Text('Ask questions'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chat/${doc.id}');
                },
              ),
            ListTile(
              leading: Icon(Symbols.delete, color: context.colors.error),
              title: Text('Delete',
                  style: TextStyle(color: context.colors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Guards the destructive delete behind a confirmation dialog. Delete is
  /// permanent — in live mode it also removes the stored file — so no undo.
  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete document?',
      message: '"${doc.name}" and its summary will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(documentRepositoryProvider)?.delete(doc.id);
    if (mounted) context.showSnack('Document deleted');
  }

  Widget _header(BuildContext context, String? name) {
    final first = (name ?? 'there').split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: context.text.bodyMedium),
                Text(first, style: context.text.headlineMedium),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: context.colors.secondaryContainer,
            child: Text(
              (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : 'U',
              style: context.text.titleMedium
                  ?.copyWith(color: context.colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search documents...',
          prefixIcon: const Icon(Symbols.search),
          filled: true,
          fillColor: context.colors.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    const labels = {
      _Filter.all: 'All',
      _Filter.recent: 'Recent',
      _Filter.favorites: 'Favorites',
      _Filter.pdfs: 'PDFs',
    };
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        children: [
          for (final f in _Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(labels[f]!),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                labelStyle: TextStyle(
                  color: _filter == f
                      ? context.colors.onPrimary
                      : context.colors.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('MY DOCUMENTS',
              style: context.text.labelMedium
                  ?.copyWith(letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
