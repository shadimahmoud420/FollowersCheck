import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/common.dart';
import '../domain/report_reason.dart';

/// نافذة الإبلاغ عن مستخدم أو إعلان أو رسالة
Future<void> showReportSheet(
  BuildContext context, {
  String? userId,
  String? listingId,
  int? messageId,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReportSheet(userId: userId, listingId: listingId, messageId: messageId),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({this.userId, this.listingId, this.messageId});
  final String? userId;
  final String? listingId;
  final int? messageId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => ref.read(safetyRepositoryProvider).report(
            reason: _reason!,
            userId: widget.userId,
            listingId: widget.listingId,
            messageId: widget.messageId,
            details: _details.text,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context);
      showMessage(context, 'شكراً لك. سيراجع فريق الإشراف البلاغ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إبلاغ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(children: [
                for (final r in ReportReason.values)
                  RadioListTile<ReportReason>(
                    value: r,
                    title: Text(r.label),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ]),
            ),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'تفاصيل إضافية (اختياري)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _reason == null || _busy ? null : _submit,
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// حظر مستخدم بعد التأكيد. يرجع true إذا تم الحظر.
Future<bool> confirmAndBlock(BuildContext context, WidgetRef ref, String userId, String name) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('حظر $name؟'),
      content: const Text('لن يرى أحدكما إعلانات الآخر، ولن يتمكن من مراسلتك أو إرسال عروض لك.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حظر')),
      ],
    ),
  );
  if (yes != true || !context.mounted) return false;
  final ok = await runGuarded(context, () => ref.read(safetyRepositoryProvider).block(userId));
  if (ok && context.mounted) showMessage(context, 'تم الحظر');
  return ok;
}
