import 'package:flutter/material.dart';

import '../domain/reference_models.dart';

/// اختيار المحافظة ثم المنطقة (اختيارية).
class RegionPicker extends StatelessWidget {
  const RegionPicker({
    super.key,
    required this.data,
    required this.governorateId,
    required this.areaId,
    required this.onChanged,
    this.allowAny = false,
  });

  final ReferenceData data;
  final int? governorateId;
  final int? areaId;
  final void Function(int? governorateId, int? areaId) onChanged;

  /// في الفلاتر: خيار «كل القطاع»
  final bool allowAny;

  @override
  Widget build(BuildContext context) {
    final areas = data.areasOf(governorateId);
    return Column(
      children: [
        DropdownButtonFormField<int?>(
          initialValue: governorateId,
          decoration: const InputDecoration(labelText: 'المحافظة'),
          items: [
            if (allowAny) const DropdownMenuItem(value: null, child: Text('كل القطاع')),
            for (final g in data.governorates)
              DropdownMenuItem(value: g.id, child: Text(g.nameAr)),
          ],
          onChanged: (g) => onChanged(g, null),
        ),
        if (governorateId != null && areas.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey('areas-$governorateId'),
            initialValue: areaId,
            decoration: const InputDecoration(labelText: 'المنطقة (اختياري)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('كل المناطق')),
              for (final a in areas) DropdownMenuItem(value: a.id, child: Text(a.nameAr)),
            ],
            onChanged: (a) => onChanged(governorateId, a),
          ),
        ],
      ],
    );
  }
}
