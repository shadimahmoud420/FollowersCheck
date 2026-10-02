import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session.dart';
import '../../reference/domain/reference_models.dart';
import '../../reference/presentation/reference_providers.dart';
import '../../reference/presentation/region_picker.dart';
import '../data/image_compressor.dart';
import '../domain/listing.dart';
import 'listing_providers.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  static const maxImages = 8;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _value = TextEditingController();
  final _wantsNote = TextEditingController();
  final _images = <Uint8List>[];
  final _wants = <ListingWant>[];

  int? _categoryId;
  ItemCondition? _condition;
  bool _wantsAnything = false;
  bool _acceptsCash = true;
  ListingDuration _duration = ListingDuration.open;
  int? _governorateId;
  int? _areaId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final me = ref.read(myProfileProvider);
    _governorateId = me?.governorateId;
    _areaId = me?.areaId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _value.dispose();
    _wantsNote.dispose();
    super.dispose();
  }

  Future<void> _addImages(ImageSource source) async {
    final picker = ImagePicker();
    final files = source == ImageSource.camera
        ? [?await picker.pickImage(source: ImageSource.camera)]
        : await picker.pickMultiImage(limit: maxImages - _images.length);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    for (final f in files.take(maxImages - _images.length)) {
      final bytes = await ImageCompressor.compress(f);
      if (!mounted) return;
      setState(() => _images.add(bytes));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addWant(ReferenceData data) async {
    final want = await showModalBottomSheet<ListingWant>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WantPicker(data: data),
    );
    if (want != null && !_wants.contains(want)) setState(() => _wants.add(want));
  }

  String? _validate() {
    if (_images.isEmpty) return 'أضف صورة واحدة على الأقل';
    if (_title.text.trim().length < 2) return 'اكتب اسم الغرض';
    if (_categoryId == null) return 'اختر الفئة';
    if (_condition == null) return 'اختر حالة الغرض';
    if (_governorateId == null) return 'اختر المحافظة';
    if (!_wantsAnything && _wants.isEmpty && _wantsNote.text.trim().isEmpty) {
      return 'حدّد ماذا تريد مقابله، أو فعّل «أي شيء مناسب»';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      showMessage(context, error, error: true);
      return;
    }
    setState(() => _busy = true);
    final draft = ListingDraft(
      title: _title.text,
      description: _description.text,
      categoryId: _categoryId!,
      condition: _condition!,
      governorateId: _governorateId!,
      areaId: _areaId,
      estimatedValue: double.tryParse(toLatinDigits(_value.text.trim())),
      wantsAnything: _wantsAnything,
      wantsNote: _wantsNote.text,
      wants: _wants,
      acceptsCashDifference: _acceptsCash,
      duration: _duration,
    );
    Listing? created;
    final ok = await runGuarded(context, () async {
      created = await ref.read(listingRepositoryProvider).create(draft, _images);
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && created != null) {
      ref.invalidate(feedProvider);
      ref.invalidate(myListingsProvider);
      showMessage(context, 'تم نشر غرضك 🎉');
      context.pushReplacement('/listing/${created!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = ref.watch(referenceDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('أضف شيئاً للتبادل')),
      body: AsyncView(
        value: refData,
        onRetry: () => ref.invalidate(referenceDataProvider),
        data: (data) => AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _label('الصور (${_images.length}/$maxImages)'),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_images.length < maxImages) ...[
                      _AddImageButton(
                          icon: Icons.photo_library_outlined,
                          label: 'المعرض',
                          onTap: () => _addImages(ImageSource.gallery)),
                      _AddImageButton(
                          icon: Icons.photo_camera_outlined,
                          label: 'الكاميرا',
                          onTap: () => _addImages(ImageSource.camera)),
                    ],
                    for (var i = 0; i < _images.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_images[i], width: 96, height: 96, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2, left: 2,
                            child: InkWell(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 14, color: Colors.white)),
                            ),
                          ),
                          if (i == 0)
                            const Positioned(
                              bottom: 4, right: 4,
                              child: Text('الغلاف',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      shadows: [Shadow(blurRadius: 4)])),
                            ),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _title,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'اسم الغرض',
                  hintText: 'مثال: لوح طاقة شمسية 300 واط',
                ),
              ),
              _label('الفئة'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in data.categories)
                  ChoiceChip(
                    avatar: Icon(categoryIcon(c.icon), size: 18),
                    label: Text(c.nameAr),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ]),
              _label('الحالة'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in ItemCondition.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _condition == c,
                    onSelected: (_) => setState(() => _condition = c),
                  ),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'اشرح حالة الغرض وأي عيوب فيه بصدق',
                  alignLabelWithHint: true,
                ),
              ),
              TextField(
                controller: _value,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'القيمة التقريبية بالشيكل (اختياري)',
                  suffixText: '₪',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔄 ماذا تريد مقابله؟',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('كلما حددت أكثر، وجدنا لك تطابقات أدق.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final w in _wants)
                        InputChip(
                          label: Text([data.category(w.categoryId)?.nameAr, w.keyword]
                              .whereType<String>()
                              .join(' · ')),
                          onDeleted: () => setState(() => _wants.remove(w)),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('أضف ما تريده'),
                        onPressed: () => _addWant(data),
                      ),
                    ]),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('أقبل أي شيء مناسب'),
                      value: _wantsAnything,
                      onChanged: (v) => setState(() => _wantsAnything = v),
                    ),
                    TextField(
                      controller: _wantsNote,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        hintText: 'ملاحظة (اختياري): مثلاً هاتف بذاكرة 128 أو أكثر',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('أقبل تبادل + فرق نقدي'),
                      subtitle: const Text('يتفق الطرفان على الفرق، والتطبيق لا يتعامل بالمال'),
                      value: _acceptsCash,
                      onChanged: (v) => setState(() => _acceptsCash = v),
                    ),
                  ],
                ),
              ),
              _label('الموقع'),
              RegionPicker(
                data: data,
                governorateId: _governorateId,
                areaId: _areaId,
                onChanged: (g, a) => setState(() {
                  _governorateId = g;
                  _areaId = a;
                }),
              ),
              _label('مدة العرض'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final d in ListingDuration.values)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: _duration == d,
                    onSelected: (_) => setState(() => _duration = d),
                  ),
              ]),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('انشر للتبادل'),
              ),
              const SizedBox(height: 8),
              const Text(
                'يُمنع نشر الأدوية والمساعدات المخصصة للتوزيع المجاني وأي غرض مخالف.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}

/// اختيار رغبة منظّمة: فئة + كلمة مفتاحية اختيارية
class _WantPicker extends StatefulWidget {
  const _WantPicker({required this.data});
  final ReferenceData data;

  @override
  State<_WantPicker> createState() => _WantPickerState();
}

class _WantPickerState extends State<_WantPicker> {
  int? _categoryId;
  final _keyword = TextEditingController();

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ماذا تريد؟', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in widget.data.categories)
              ChoiceChip(
                avatar: Icon(categoryIcon(c.icon), size: 18),
                label: Text(c.nameAr),
                selected: _categoryId == c.id,
                onSelected: (_) => setState(() => _categoryId = c.id),
              ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _keyword,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'تحديد أكثر (اختياري)',
              hintText: 'مثال: سامسونج، بطارية، مقاس 8 سنوات',
            ),
          ),
          FilledButton(
            onPressed: _categoryId == null
                ? null
                : () => Navigator.pop(
                      context,
                      ListingWant(
                        categoryId: _categoryId!,
                        keyword: _keyword.text.trim().isEmpty ? null : _keyword.text.trim(),
                      ),
                    ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
