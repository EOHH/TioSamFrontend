import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_trade_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AnimeTradeApp(),
      ),
    );

    // Solo verificamos que la app carga (puedes ajustar luego)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}