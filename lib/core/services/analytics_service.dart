import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logTradeCreated({required String tradeId}) async {
    await _analytics.logEvent(
      name: 'trade_created',
      parameters: {
        'trade_id': tradeId,
      },
    );
  }

  Future<void> logGemPurchase({required String packageId, required double price}) async {
    await _analytics.logEvent(
      name: 'gem_purchase',
      parameters: {
        'package_id': packageId,
        'price': price,
      },
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
