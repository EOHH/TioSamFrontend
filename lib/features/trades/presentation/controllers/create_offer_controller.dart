import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/offer_repository.dart';

class CreateOfferController extends StateNotifier<AsyncValue<void>> {
  final OfferRepository _repository;

  CreateOfferController(this._repository) : super(const AsyncData(null));

  Future<bool> sendOffer(String postId, String message) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() =>
        _repository.submitOffer(postId: postId, message: message)
    );

    state = result;
    return !result.hasError;
  }
}

final createOfferControllerProvider = StateNotifierProvider<CreateOfferController, AsyncValue<void>>((ref) {
  return CreateOfferController(ref.watch(offerRepositoryProvider));
});