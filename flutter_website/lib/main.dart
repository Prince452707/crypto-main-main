import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/dashboard/providers/optimized_crypto_provider.dart';
import 'features/dashboard/providers/crypto_provider.dart';
import 'features/analysis/providers/analysis_provider.dart';
import 'features/portfolio/providers/portfolio_provider.dart';
import 'features/news/providers/news_provider.dart';
import 'features/alerts/providers/alerts_provider.dart';
import 'features/watchlist/providers/watchlist_provider.dart';
import 'features/bookmarks/providers/bookmark_provider.dart';
import 'features/similar_cryptos/providers/similar_cryptos_provider.dart';
import 'features/crypto_detail/providers/crypto_detail_provider.dart';
import 'features/crypto_detail/providers/focused_crypto_provider.dart';
import 'core/services/optimized_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  runApp(const CryptoInsightApp());
}

class CryptoInsightApp extends StatelessWidget {
  const CryptoInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OptimizedCryptoProvider()..loadMarketData(showLoading: false),
        ),
        ChangeNotifierProvider(
          create: (_) => CryptoProvider()..loadMarketData(),
        ),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => SimilarCryptosProvider()),
        ChangeNotifierProvider(create: (_) => CryptoDetailProvider()),
        ChangeNotifierProvider(create: (_) => FocusedCryptoProvider()),
        Provider(create: (_) => OptimizedApiService()),
      ],
      child: MaterialApp.router(
        title: 'Crypto Insight Pro - Advanced Trading Platform',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // Performance optimizations
        showPerformanceOverlay: false,
        checkerboardRasterCacheImages: false,
        checkerboardOffscreenLayers: false,
        showSemanticsDebugger: false,
      ),
    );
  }
}
