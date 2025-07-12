import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:crypto_insight_web/core/services/api_service.dart';
import 'package:crypto_insight_web/core/services/realtime_service.dart';
import 'package:crypto_insight_web/features/dashboard/providers/crypto_provider.dart';

void main() {
  group('Real-time Service Tests', () {
    late ApiService apiService;
    late RealTimeService realTimeService;

    setUp(() {
      apiService = ApiService();
      realTimeService = RealTimeService(apiService);
    });

    tearDown(() {
      realTimeService.dispose();
      apiService.dispose();
    });

    test('should initialize with correct default values', () {
      expect(realTimeService.isHealthy, false);
      expect(realTimeService.systemStatus, isEmpty);
    });

    test('should track symbol refresh state', () {
      const symbol = 'BTC';
      expect(realTimeService.isRefreshing(symbol), false);
      expect(realTimeService.getLastUpdated(symbol), isNull);
      expect(realTimeService.isDataFresh(symbol), false);
    });

    test('should format data age correctly', () {
      const symbol = 'BTC';
      expect(realTimeService.getDataAge(symbol), 'Unknown');
    });
  });

  group('CryptoProvider Tests', () {
    late CryptoProvider cryptoProvider;

    setUp(() {
      cryptoProvider = CryptoProvider();
    });

    tearDown(() {
      cryptoProvider.dispose();
    });

    test('should initialize with correct default values', () {
      expect(cryptoProvider.marketData, isEmpty);
      expect(cryptoProvider.searchResults, isEmpty);
      expect(cryptoProvider.isLoading, false);
      expect(cryptoProvider.isSearching, false);
      expect(cryptoProvider.error, isNull);
      expect(cryptoProvider.searchQuery, isEmpty);
      expect(cryptoProvider.realTimeEnabled, true);
    });

    test('should provide access to real-time service', () {
      expect(cryptoProvider.realTimeService, isNotNull);
    });
  });

  group('Widget Tests', () {
    testWidgets('CryptoProvider should be accessible in widget tree', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CryptoProvider(),
          child: MaterialApp(
            home: Consumer<CryptoProvider>(
              builder: (context, provider, child) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Real-time: ${provider.realTimeEnabled}',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Real-time: true'), findsOneWidget);
    });
  });
}
