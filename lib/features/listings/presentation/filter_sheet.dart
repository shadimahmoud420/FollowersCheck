import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/arabic.dart';
import '../../reference/presentation/reference_providers.dart';
import '../../reference/presentation/region_picker.dart';
import '../domain/listing.dart';
import '../domain/listing_filter.dart';
import 'listing_providers.dart';

Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ListingFilter _f = ref.read(listingFilterProvider);
  late final _min = TextEditingController(text: _f.minValue?.toStringAsFixed(0) ?? '');
  late final _max = TextEditingController(text: _f.maxValue?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(toLatinDigits(s.trim()));

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(referenceDataProvider).value;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الفلاتر', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (data != null)
              RegionPicker(
                data: data,
                allowAny: true,
                governorateId: _f.governorateId,
                areaId: _f.areaId,
                onChanged: (g, a) => setState(
                    () => _f = _f.copyWith(governorateId: () => g, areaId: () => a)),
              ),
            const SizedBox(height: 16),
            const Text('الحالة'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in ItemCondition.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _f.condition == c,
                  onSelected: (v) =>
                      setState(() => _f = _f.copyWith(condition: () => v ? c : null)),
                ),
            ]),
            const SizedBox(height: 16),
            const Text('القيمة التقريبية (شيكل)'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'من'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'إلى'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('الترتيب'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ListingSort.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _f.sort == s,
                  onSelected: (_) => setState(() => _f = _f.copyWith(sort: s)),
                ),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(listingFilterProvider.notifier).set(_f.copyWith(
                      minValue: () => _num(_min.text),
                      maxValue: () => _num(_max.text),
                    ));
                Navigator.pop(context);
              },
              child: const Text('عرض النتائج'),
            ),
            TextButton(
              onPressed: () {
                final current = ref.read(listingFilterProvider);
                ref.read(listingFilterProvider.notifier).set(ListingFilter(
                    query: current.query, categoryId: current.categoryId));
                Navigator.pop(context);
              },
              child: const Text('مسح الفلاتر'),
            ),
          ],
        ),
      ),
    );
  }
}
