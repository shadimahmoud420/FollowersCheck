import 'listing.dart';

enum ListingSort {
  newest('الأحدث'),
  endingSoon('تنتهي قريباً'),
  valueHigh('الأعلى قيمة'),
  valueLow('الأقل قيمة');

  const ListingSort(this.label);
  final String label;
}

class ListingFilter {
  const ListingFilter({
    this.query = '',
    this.categoryId,
    this.governorateId,
    this.areaId,
    this.condition,
    this.minValue,
    this.maxValue,
    this.sort = ListingSort.newest,
  });

  final String query;
  final int? categoryId;
  final int? governorateId;
  final int? areaId;
  final ItemCondition? condition;
  final double? minValue;
  final double? maxValue;
  final ListingSort sort;

  /// عدد الفلاتر المفعّلة (لإظهار شارة على زر الفلاتر)
  int get activeCount => [
        governorateId,
        areaId,
        condition,
        minValue,
        maxValue,
        sort == ListingSort.newest ? null : sort,
      ].whereType<Object>().length;

  ListingFilter copyWith({
    String? query,
    int? Function()? categoryId,
    int? Function()? governorateId,
    int? Function()? areaId,
    ItemCondition? Function()? condition,
    double? Function()? minValue,
    double? Function()? maxValue,
    ListingSort? sort,
  }) =>
      ListingFilter(
        query: query ?? this.query,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        governorateId: governorateId != null ? governorateId() : this.governorateId,
        areaId: areaId != null ? areaId() : this.areaId,
        condition: condition != null ? condition() : this.condition,
        minValue: minValue != null ? minValue() : this.minValue,
        maxValue: maxValue != null ? maxValue() : this.maxValue,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is ListingFilter &&
      other.query == query &&
      other.categoryId == categoryId &&
      other.governorateId == governorateId &&
      other.areaId == areaId &&
      other.condition == condition &&
      other.minValue == minValue &&
      other.maxValue == maxValue &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, categoryId, governorateId, areaId,
      condition, minValue, maxValue, sort);
}
