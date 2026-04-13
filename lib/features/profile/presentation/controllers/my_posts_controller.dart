import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../trades/data/trade_repository.dart';
import '../../../trades/domain/models/trade_post.dart';

class HomeFeedController extends StateNotifier<AsyncValue<List<TradePost>>> {
  final TradeRepository _repository;

  HomeFeedController(this._repository) : super(const AsyncLoading()) {
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getTrades());
  }
}

final homeFeedProvider = StateNotifierProvider.autoDispose<HomeFeedController, AsyncValue<List<TradePost>>>((ref) {
  return HomeFeedController(ref.watch(tradeRepositoryProvider));
});