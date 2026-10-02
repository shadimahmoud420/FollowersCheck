import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session.dart';
import '../../listings/data/image_compressor.dart';
import '../../reference/presentation/reference_providers.dart';
import '../../reference/presentation/region_picker.dart';

/// تُستخدم للإعداد الأول (onboarding) ولتعديل الملف لاحقاً.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  int? _governorateId;
  int? _areaId;
  String? _avatarPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(myProfileProvider);
    _name = TextEditingController(text: p?.displayName ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    _governorateId = p?.governorateId;
    _areaId = p?.areaId;
    _avatarPath = p?.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    await runGuarded(context, () async {
      final bytes = await ImageCompressor.compress(file);
      final path = await ref.read(profileRepositoryProvider).uploadAvatar(bytes);
      setState(() => _avatarPath = path);
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showMessage(context, 'اكتب اسماً من حرفين على الأقل', error: true);
      return;
    }
    if (_governorateId == null) {
      showMessage(context, 'اختر المحافظة', error: true);
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(profileRepositoryProvider).upsertMine(
            displayName: _name.text,
            governorateId: _governorateId!,
            areaId: _areaId,
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
            avatarPath: _avatarPath,
          );
      await ref.read(sessionProvider.notifier).refresh();
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && !widget.isOnboarding) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final urls = ref.watch(storageUrlsProvider);
    final refData = ref.watch(referenceDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'أهلاً بك في بدّلها 👋' : 'تعديل الملف'),
        actions: [
          if (widget.isOnboarding)
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('خروج'),
            ),
        ],
      ),
      body: AsyncView(
        value: refData,
        onRetry: () => ref.invalidate(referenceDataProvider),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.isOnboarding)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('عرّفنا بنفسك واختر منطقتك حتى نعرض لك الأغراض القريبة منك.'),
              ),
            Center(
              child: GestureDetector(
                onTap: _busy ? null : _pickAvatar,
                child: Stack(
                  children: [
                    Avatar(name: _name.text, url: urls.avatar(_avatarPath), radius: 44),
                    const Positioned(
                      bottom: 0, left: 0,
                      child: CircleAvatar(radius: 14, child: Icon(Icons.camera_alt, size: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'الاسم الذي يظهر للآخرين'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            RegionPicker(
              data: data,
              governorateId: _governorateId,
              areaId: _areaId,
              onChanged: (g, a) => setState(() {
                _governorateId = g;
                _areaId = a;
              }),
            ),
            const SizedBox(height: 8),
            const Text('📍 نعرض المحافظة والمنطقة فقط، ولا نطلب موقعك الدقيق أبداً.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نبذة (اختياري)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(widget.isOnboarding ? 'ابدأ التبديل' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
