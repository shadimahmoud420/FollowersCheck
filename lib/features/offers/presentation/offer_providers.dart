import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/offer.dart';

final incomingOffersProvider = FutureProvider.autoDispose<List<SwapOffer>>(
  (ref) => ref.watch(offerRepositoryProvider).incoming(),
);

final outgoingOffersProvider = FutureProvider.autoDispose<List<SwapOffer>>(
  (ref) => ref.watch(offerRepositoryProvider).outgoing(),
);

final offerProvider = FutureProvider.autoDispose.family<SwapOffer, String>(
  (ref, id) => ref.watch(offerRepositoryProvider).getById(id),
);

final hasRatedProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, offerId) => ref.watch(offerRepositoryProvider).hasRated(offerId),
);

