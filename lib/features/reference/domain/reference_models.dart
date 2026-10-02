class Governorate {
  const Governorate({required this.id, required this.nameAr});
  final int id;
  final String nameAr;

  factory Governorate.fromJson(Map<String, dynamic> j) =>
      Governorate(id: j['id'] as int, nameAr: j['name_ar'] as String);
}

class Area {
  const Area({required this.id, required this.governorateId, required this.nameAr});
  final int id;
  final int governorateId;
  final String nameAr;

  factory Area.fromJson(Map<String, dynamic> j) => Area(
        id: j['id'] as int,
        governorateId: j['governorate_id'] as int,
        nameAr: j['name_ar'] as String,
      );
}

class Category {
  const Category({required this.id, required this.slug, required this.nameAr, required this.icon});
  final int id;
  final String slug;
  final String nameAr;
  final String icon;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        slug: j['slug'] as String,
        nameAr: j['name_ar'] as String,
        icon: j['icon'] as String,
      );
}

/// البيانات المرجعية كاملة، تُحمّل مرة واحدة عند فتح التطبيق.
class ReferenceData {
  const ReferenceData({
    required this.governorates,
    required this.areas,
    required this.categories,
  });

  final List<Governorate> governorates;
  final List<Area> areas;
  final List<Category> categories;

  List<Area> areasOf(int? governorateId) =>
      areas.where((a) => a.governorateId == governorateId).toList();

  Category? category(int? id) => _find(categories, (c) => c.id == id);
  Governorate? governorate(int? id) => _find(governorates, (g) => g.id == id);
  Area? area(int? id) => _find(areas, (a) => a.id == id);

  /// «الرمال، غزة» أو «غزة» فقط
  String placeLabel(int? governorateId, int? areaId) {
    final g = governorate(governorateId)?.nameAr;
    final a = area(areaId)?.nameAr;
    return [a, g].whereType<String>().join('، ');
  }

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final x in list) {
      if (test(x)) return x;
    }
    return null;
  }
}
