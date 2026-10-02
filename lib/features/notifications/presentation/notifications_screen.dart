import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/common.dart';
import '../domain/app_notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  if (ref.watch(currentUserIdProvider) == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watch();
});

final unreadCountProvider = Provider<int>((ref) =>
    ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0);

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: 'الإشعارات',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void dispose() {
    // تعليم الكل كمقروء عند المغادرة
    ref.read(notificationRepositoryProvider).markAllRead().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: AsyncView(
        value: value,
        data: (items) => items.isEmpty
            ? const EmptyView(
                icon: Icons.notifications_off_outlined,
                title: 'لا توجد إشعارات بعد',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    tileColor: n.isRead ? null : AppColors.primary.withValues(alpha: 0.05),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.w700)),
                    subtitle: n.subtitle == null ? null : Text(n.subtitle!, maxLines: 1),
                    trailing: Text(timeAgo(n.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    onTap: n.route == null ? null : () => context.push(n.route!),
                  );
                },
              ),
      ),
    );
  }
}
