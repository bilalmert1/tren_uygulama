import 'dart:async';
import 'package:flutter/material.dart';
import '../services/time_service.dart';
import '../providers/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'home_map_screen.dart';
import 'favorites_screen.dart';
import 'baskent_kart_screen.dart';
import 'duyurular_screen.dart';
import 'sorun_bildir_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    BaskentKartScreen(),
    HomeMapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';

        return Scaffold(
          drawer: _buildDrawer(context, isEN),
          appBar: AppBar(
            backgroundColor: AppColors.primaryNavy,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_transparent.png',
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Text('🚆', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ANKARA BANLİYÖ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: const [], // Removed clock as requested
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.cardWhite,
                elevation: 0,
                selectedItemColor: AppColors.primaryBlue,
                unselectedItemColor: AppColors.lightBlue,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: isEN ? 'Home' : 'Ana Sayfa',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.star_outline),
                    activeIcon: const Icon(Icons.star),
                    label: isEN ? 'Favorites' : 'Favoriler',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.credit_card_outlined),
                    activeIcon: Icon(Icons.credit_card),
                    label: 'BaşkentKart',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.map_outlined),
                    activeIcon: const Icon(Icons.map),
                    label: isEN ? 'Map' : 'Harita',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, bool isEN) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                image: DecorationImage(
                  image: AssetImage('assets/images/drawer_header_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo_transparent.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => const Text('🚆', style: TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Ankara Banliyö', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const Text('Başkentray Hattı', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  const Text('Sincan ↔ Kayaş', style: TextStyle(color: AppColors.accentYellow, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.campaign_outlined,
              iconColor: Colors.orange,
              title: isEN ? 'Announcements' : 'Duyurular',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DuyurularScreen()));
              },
            ),
            _drawerItem(
              icon: Icons.report_problem_outlined,
              iconColor: Colors.red,
              title: isEN ? 'Report Issue' : 'Sorun Bildir',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SorunBildirScreen()));
              },
            ),
            _drawerItem(
              icon: Icons.share_outlined,
              iconColor: Colors.purple,
              title: isEN ? 'Social Media' : 'Sosyal Medya',
              onTap: () => _launchURL('https://www.instagram.com/lbmb_06/'),
            ),
            _drawerItem(
              icon: Icons.attach_money,
              iconColor: Colors.green,
              title: isEN ? 'Transport Fares' : 'Taşıma Ücretleri',
              onTap: () => _launchURL('https://www.ego.gov.tr/tr/sayfa/2098/tasima-ucretleri'),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                isEN ? 'Language' : 'Dil Seçimi',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _langBtn(
                    label: '🇹🇷  Türkçe',
                    isSelected: !isEN,
                    onTap: () => AppState.instance.setLocale(const Locale('tr', 'TR')),
                  ),
                  const SizedBox(width: 10),
                  _langBtn(
                    label: '🇬🇧  İngilizce',
                    isSelected: isEN,
                    onTap: () => AppState.instance.setLocale(const Locale('en', 'US')),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('© 2026 BMB', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required Color iconColor, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }

  Widget _langBtn({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textMedium,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
