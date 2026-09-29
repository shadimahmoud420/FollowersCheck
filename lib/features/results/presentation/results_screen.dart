import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting.dart';
import '../../../core/profile_links.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../snapshots/application/snapshot_providers.dart';
import '../../snapshots/domain/snapshot_diff.dart';

/// Shows the comparison for [snapshotId], or for the latest snapshot when
/// null (the home tab).
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, this.snapshotId});

  final int? snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final comparison = ref.watch(comparisonProvider(snapshotId));
    final isHome = snapshotId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultsTitle),
        actions: [
          if (isHome)
            IconButton(
              tooltip: l10n.newImport,
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: () => context.push('/import'),
            ),
        ],
      ),
      floatingActionButton: isHome && (comparison.value != null)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/import'),
              icon: const Icon(Icons.add),
              label: Text(l10n.newImport),
            )
          : null,
      body: comparison.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (result) => result == null ? const _NoDataView() : _ComparisonView(result: result),
      ),
    );
  }
}

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.noDataTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.noDataBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('empty_import'),
              onPressed: () => context.push('/import'),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.importPick),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonView extends StatefulWidget {
  const _ComparisonView({required this.result});

  final ComparisonResult result;

  @override
  State<_ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<_ComparisonView> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.result;
    final header = r.previous == null
        ? l10n.snapshotFrom(formatDate(context, r.latest.createdAt))
        : l10n.comparing(formatDate(context, r.previous!.createdAt), formatDate(context, r.latest.createdAt));

    final tabs = [
      (
        label: l10n.tabUnfollowed,
        items: r.unfollowedYou,
        empty: r.hasPrevious ? l10n.emptyList : l10n.needsTwoSnapshots,
      ),
      (
        label: l10n.tabNotFollowingBack,
        items: r.notFollowingBack,
        empty: r.latest.hasFollowingData ? l10n.emptyList : l10n.followingUnavailable,
      ),
      (
        label: l10n.tabNewFollowers,
        items: r.newFollowers,
        empty: r.hasPrevious ? l10n.emptyList : l10n.needsTwoSnapshots,
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(header, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('results_search'),
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase().replaceFirst('@', '')),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final t in tabs)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.label),
                      const SizedBox(width: 6),
                      Badge(
                        label: Text('${t.items.length}'),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [for (final t in tabs) _UserList(items: t.items, query: _query, emptyMessage: t.empty)],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.items, required this.query, required this.emptyMessage});

  final List<String> items;
  final String query;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filtered = query.isEmpty ? items : items.where((u) => u.contains(query)).toList();

    if (items.isEmpty) {
      return _Message(icon: Icons.inbox_outlined, text: emptyMessage);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              query.isEmpty ? l10n.totalCount(items.length) : l10n.shownCount(filtered.length, items.length),
              key: const Key('results_counter'),
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _Message(icon: Icons.search_off, text: l10n.noSearchResults)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final username = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(username.characters.first.toUpperCase())),
                      // Wrapped in a left-to-right isolate so "@name" renders
                      // correctly inside the Arabic (RTL) UI.
                      title: Text('\u2066@$username\u2069'),
                      trailing: IconButton(
                        tooltip: l10n.openProfile,
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => openProfile(context, username),
                      ),
                      onTap: () => openProfile(context, username),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
