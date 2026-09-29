import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting.dart';
import '../../../core/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../premium/application/premium_providers.dart';
import '../../snapshots/application/snapshot_providers.dart';
import '../../snapshots/domain/snapshot.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshots = ref.watch(snapshotsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final policy = ref.watch(usagePolicyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: snapshots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (all) {
          if (all.isEmpty) {
            return Center(child: Text(l10n.historyEmpty));
          }
          final visible = policy.visibleHistoryCount(isPremium: isPremium, total: all.length);
          final hidden = all.length - visible;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChartCard(
                snapshots: all,
                locked: !policy.canViewCharts(isPremium: isPremium),
              ),
              const SizedBox(height: 16),
              for (final s in all.take(visible)) _SnapshotTile(summary: s),
              if (hidden > 0)
                Card.filled(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.historyLocked(hidden)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/paywall'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SnapshotTile extends ConsumerWidget {
  const _SnapshotTile({required this.summary});

  final SnapshotSummary summary;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSnapshotTitle),
        content: Text(l10n.deleteSnapshotBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(snapshotRepositoryProvider).deleteSnapshot(summary.id);
    ref.invalidate(snapshotsProvider);
    ref.invalidate(comparisonProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final following = summary.hasFollowingData ? ' · ${l10n.followingLabel(summary.followingCount)}' : '';
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.history)),
        title: Text(formatDate(context, summary.createdAt)),
        subtitle: Text('${l10n.followersLabel(summary.followerCount)}$following'),
        onTap: () => context.push('/history/${summary.id}'),
        trailing: IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.snapshots, required this.locked});

  /// Newest first.
  final List<SnapshotSummary> snapshots;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget content;
    if (locked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(l10n.chartLocked),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () => context.push('/paywall'), child: Text(l10n.upgrade)),
        ],
      );
    } else if (snapshots.length < 2) {
      content = Text(l10n.chartNeedsTwo, textAlign: TextAlign.center);
    } else {
      content = SizedBox(height: 200, child: _FollowersChart(snapshots: snapshots.reversed.toList()));
    }

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chartTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Center(child: content),
          ],
        ),
      ),
    );
  }
}

class _FollowersChart extends StatelessWidget {
  const _FollowersChart({required this.snapshots});

  /// Oldest first.
  final List<SnapshotSummary> snapshots;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = snapshots.map((s) => s.followerCount).toList();
    final minY = counts.reduce(math.min).toDouble();
    final maxY = counts.reduce(math.max).toDouble();
    final pad = math.max(1.0, (maxY - minY) * 0.15);
    final labelEvery = math.max(1, (snapshots.length / 4).ceil());

    // Time flows left-to-right in charts regardless of UI direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LineChart(
        LineChartData(
          minY: math.max(0, minY - pad),
          maxY: maxY + pad,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= snapshots.length || i % labelEvery != 0 || value != i.toDouble()) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(formatShortDate(context, snapshots[i].createdAt), style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < counts.length; i++) FlSpot(i.toDouble(), counts[i].toDouble())],
              isCurved: true,
              preventCurveOverShooting: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
