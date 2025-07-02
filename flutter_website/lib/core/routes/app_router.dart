import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/markets/screens/markets_screen.dart';
import '../../features/analysis/screens/analysis_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/crypto_detail/screens/crypto_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/markets',
            name: 'markets',
            builder: (context, state) => const MarketsScreen(),
          ),
          GoRoute(
            path: '/analysis',
            name: 'analysis',
            builder: (context, state) => const AnalysisScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            name: 'portfolio',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/news',
            name: 'news',
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '/crypto/:symbol',
            name: 'crypto-detail',
            builder: (context, state) {
              final symbol = state.pathParameters['symbol']!;
              return CryptoDetailScreen(symbol: symbol);
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
