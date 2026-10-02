import '../../listings/domain/listing.dart';

/// تطابق مباشر: أنت تملك [mine] وهو يملك [theirs]، وكل منكما يريد ما لدى الآخر.
class SwapMatch {
  const SwapMatch({required this.mine, required this.theirs, required this.score});
  final Listing mine;
  final Listing theirs;
  final int score;

  /// نفس المنطقة (حسب نقاط القرب في find_matches)
  bool get isNearby => score % 10 >= 1;
}
