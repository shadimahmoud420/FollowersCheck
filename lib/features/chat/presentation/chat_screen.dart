import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../listings/data/image_compressor.dart';
import '../../safety/presentation/safety_actions.dart';
import '../domain/message.dart';

final conversationProvider = FutureProvider.autoDispose.family<Conversation, String>(
  (ref, id) => ref.watch(chatRepositoryProvider).conversation(id),
);

final messagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, id) => ref.watch(chatRepositoryProvider).watchMessages(id),
);

final chatImageUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(chatRepositoryProvider).imageUrl(path),
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send({String? meetingPoint, ImageSource? image}) async {
    final body = _text.text.trim();
    if (body.isEmpty && meetingPoint == null && image == null) return;
    final repo = ref.read(chatRepositoryProvider);
    XFile? file;
    if (image != null) {
      file = await ImagePicker().pickImage(source: image);
      if (file == null || !mounted) return;
    }
    setState(() => _sending = true);
    final ok = await runGuarded(context, () async {
      await repo.send(
        widget.conversationId,
        body: image == null ? body : '',
        meetingPoint: meetingPoint,
        jpegImage: file == null ? null : await ImageCompressor.compress(file),
      );
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok && image == null && meetingPoint == null) _text.clear();
  }

  Future<void> _sendMeetingPoint() async {
    final controller = TextEditingController();
    final point = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📍 مكان اللقاء'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(hintText: 'مكان عام ومعروف، مثل: دوار الشاطئ'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('إرسال')),
        ],
      ),
    );
    controller.dispose();
    if (point != null && point.trim().isNotEmpty) await _send(meetingPoint: point);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final conv = ref.watch(conversationProvider(widget.conversationId)).value;
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final otherId = conv?.otherUser(uid);
    final other = otherId == null
        ? null
        : ref.watch(_profileProvider(otherId)).value;

    // تعليم الرسائل كمقروءة عند وصول رسائل جديدة
    ref.listen(messagesProvider(widget.conversationId), (_, next) {
      if (next.value?.any((m) => m.senderId != uid && m.readAt == null) ?? false) {
        ref.read(chatRepositoryProvider).markRead(widget.conversationId).ignore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(other?.displayName ?? 'المحادثة'),
        actions: [
          if (conv != null)
            IconButton(
              tooltip: 'تفاصيل الصفقة',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => context.push('/offer/${conv.offerId}'),
            ),
          if (otherId != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'report') showReportSheet(context, userId: otherId);
                if (v == 'block') {
                  confirmAndBlock(context, ref, otherId, other?.displayName ?? '');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('🚩 إبلاغ')),
                PopupMenuItem(value: 'block', child: Text('حظر')),
              ],
            ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          color: AppColors.warning.withValues(alpha: 0.12),
          child: const Text(
            '🛡️ لا تشارك موقعك الدقيق. التقيا في مكان عام وافحص الغرض قبل التسليم.',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: AsyncView(
            value: messages,
            onRetry: () => ref.invalidate(messagesProvider(widget.conversationId)),
            data: (items) => items.isEmpty
                ? const EmptyView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'ابدأ المحادثة لترتيب التسليم',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _Bubble(message: items[i], mine: items[i].senderId == uid),
                  ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(children: [
              IconButton(
                tooltip: 'صورة',
                onPressed: _sending ? null : () => _send(image: ImageSource.gallery),
                icon: const Icon(Icons.image_outlined),
              ),
              IconButton(
                tooltip: 'مكان اللقاء',
                onPressed: _sending ? null : _sendMeetingPoint,
                icon: const Icon(Icons.place_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'اكتب رسالة…'),
                ),
              ),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

final _profileProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(profileRepositoryProvider).getById(id),
);

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final fg = mine ? Colors.white : Colors.black87;
    return Align(
      // في RTL: رسائلي على اليمين (البداية)
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: NetImage(ref.watch(chatImageUrlProvider(m.imagePath!)).value),
                ),
              ),
            if (m.meetingPoint != null)
              Text('📍 مكان اللقاء: ${m.meetingPoint}',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            if (m.body.isNotEmpty) Text(m.body, style: TextStyle(color: fg)),
            const SizedBox(height: 2),
            Text(
              '${DateFormat.jm('ar').format(m.createdAt.toLocal())}${mine && m.readAt != null ? ' ✓✓' : ''}',
              style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
