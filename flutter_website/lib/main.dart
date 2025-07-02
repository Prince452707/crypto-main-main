import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/dashboard/providers/crypto_provider.dart';
import 'features/analysis/providers/analysis_provider.dart';
import 'features/portfolio/providers/portfolio_provider.dart';
import 'features/news/providers/news_provider.dart';
import 'core/services/api_service.dart';

void main() {
  runApp(const CryptoInsightApp());
}

class CryptoInsightApp extends StatelessWidget {
  const CryptoInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CryptoProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp.router(
        title: 'Crypto Insight Pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
