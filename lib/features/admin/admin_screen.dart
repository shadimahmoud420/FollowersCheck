import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/common.dart';
import '../safety/domain/report_reason.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(supabaseClientProvider).rpc('admin_stats');
  return (res as Map).cast<String, dynamic>();
});

final openReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('reports')
      .select('*, reporter:profiles!reports_reporter_id_fkey(display_name), '
          'reported:profiles!reports_reported_user_id_fkey(id, display_name), '
          'listing:listings(id, title)')
      .inFilter('status', ['open', 'reviewing'])
      .order('created_at', ascending: false)
      .limit(100);
  return rows;
});

/// لوحة إشراف أساسية داخل التطبيق (للمشرفين فقط؛ الصلاحيات تُفرض في قاعدة البيانات).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final reports = ref.watch(openReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإشراف')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(openReportsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncView(
              value: stats,
              data: (s) => Wrap(spacing: 10, runSpacing: 10, children: [
                _StatTile('المستخدمون', s['users']),
                _StatTile('محظورون', s['banned_users']),
                _StatTile('إعلانات نشطة', s['active_listings']),
                _StatTile('إعلانات 7 أيام', s['listings_7d']),
                _StatTile('عروض', s['offers_total']),
                _StatTile('معلّقة', s['offers_pending']),
                _StatTile('مقبولة', s['offers_accepted']),
                _StatTile('تبادلات مكتملة', s['swaps_completed']),
                _StatTile('بلاغات مفتوحة', s['open_reports']),
              ]),
            ),
            const SizedBox(height: 24),
            Text('البلاغات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncView(
              value: reports,
              data: (items) => items.isEmpty
                  ? const Text('لا توجد بلاغات مفتوحة ✅')
                  : Column(children: [for (final r in items) _ReportCard(report: r)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ),
      );
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;

  Future<void> _close(BuildContext context, WidgetRef ref, String status) async {
    final db = ref.read(supabaseClientProvider);
    await runGuarded(context, () => db.from('reports').update({
          'status': status,
          'handled_by': db.auth.currentUser!.id,
          'handled_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', report['id'] as int));
    ref.invalidate(openReportsProvider);
    ref.invalidate(adminStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = ReportReason.values
        .firstWhere((r) => r.db == report['reason'], orElse: () => ReportReason.other);
    final reported = report['reported'] as Map?;
    final listing = report['listing'] as Map?;
    final db = ref.read(supabaseClientProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(reason.label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
            const Spacer(),
            Text(timeAgo(DateTime.parse(report['created_at'] as String)),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          Text('من: ${(report['reporter'] as Map?)?['display_name'] ?? ''}'),
          if (reported != null)
            InkWell(
              onTap: () => context.push('/user/${reported['id']}'),
              child: Text('ضد: ${reported['display_name']}',
                  style: const TextStyle(color: AppColors.primary)),
            ),
          if (listing != null)
            InkWell(
              onTap: () => context.push('/listing/${listing['id']}'),
              child: Text('الإعلان: ${listing['title']}',
                  style: const TextStyle(color: AppColors.primary)),
            ),
          if ((report['details'] as String?)?.isNotEmpty ?? false) Text(report['details'] as String),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            OutlinedButton(
              onPressed: () => _close(context, ref, 'dismissed'),
              child: const Text('تجاهل'),
            ),
            if (listing != null)
              OutlinedButton(
                onPressed: () async {
                  await runGuarded(context,
                      () => db.from('listings').update({'status': 'removed'}).eq('id', listing['id'] as String));
                  if (context.mounted) await _close(context, ref, 'actioned');
                },
                child: const Text('حذف الإعلان'),
              ),
            if (reported != null)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger, minimumSize: const Size(0, 40)),
                onPressed: () async {
                  await runGuarded(context, () => db.rpc('admin_set_ban',
                      params: {'p_user': reported['id'], 'p_banned': true}));
                  if (context.mounted) await _close(context, ref, 'actioned');
                },
                child: const Text('حظر المستخدم'),
              ),
          ]),
        ]),
      ),
    );
  }
}
