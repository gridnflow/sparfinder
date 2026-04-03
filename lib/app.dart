import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/offer.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/product_detail/product_detail_screen.dart';
import 'presentation/screens/saved/saved_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

class SparFinderApp extends StatelessWidget {
  const SparFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AngebotsFuchs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _MainShell(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/product':
            final offer = settings.arguments;
            if (offer is! Offer) return null;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(offer: offer),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _selectedIndex = 0;

  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    SavedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          border: const Border(
            top: BorderSide(color: AppTheme.divider, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer_rounded, color: AppTheme.accentOrange),
              label: 'Angebote',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded, color: AppTheme.accentOrange),
              label: 'Vergleich',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded, color: AppTheme.accentOrange),
              label: 'Merkliste',
            ),
          ],
        ),
      ),
    );
  }
}
