import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class YakinBayilerScreen extends StatelessWidget {
  const YakinBayilerScreen({super.key});

  static final List<_Bayi> _bayiler = [
    _Bayi(
      istasyon: 'Ankara Garı',
      isim: 'EGO Ankara Garı Satış Noktası',
      isimEN: 'EGO Ankara Station Sales Point',
      adres: 'Ankara Garı, Gar Meydanı, Altındağ/Ankara',
      adresEN: 'Ankara Station, Gar Square, Altındağ/Ankara',
      tip: 'EGO Satış Ofisi',
      tipEN: 'EGO Sales Office',
    ),
    _Bayi(
      istasyon: 'Etimesgut',
      isim: 'Etimesgut EGO Satış Noktası',
      isimEN: 'Etimesgut EGO Sales Point',
      adres: 'Etimesgut İstasyonu Çevresi, Etimesgut/Ankara',
      adresEN: 'Around Etimesgut Station, Etimesgut/Ankara',
      tip: 'Yetkili Bayi',
      tipEN: 'Authorized Dealer',
    ),
    _Bayi(
      istasyon: 'Sincan',
      isim: 'Sincan Terminal Satış Noktası',
      isimEN: 'Sincan Terminal Sales Point',
      adres: 'Sincan İstasyonu, Sincan/Ankara',
      adresEN: 'Sincan Station, Sincan/Ankara',
      tip: 'EGO Satış Ofisi',
      tipEN: 'EGO Sales Office',
    ),
    _Bayi(
      istasyon: 'Kayaş',
      isim: 'Kayaş Terminal Satış Noktası',
      isimEN: 'Kayaş Terminal Sales Point',
      adres: 'Kayaş İstasyonu, Mamak/Ankara',
      adresEN: 'Kayaş Station, Mamak/Ankara',
      tip: 'EGO Satış Ofisi',
      tipEN: 'EGO Sales Office',
    ),
    _Bayi(
      istasyon: 'Hipodrom',
      isim: 'EGO Genel Müdürlüğü',
      isimEN: 'EGO General Directorate',
      adres: 'Hipodrom Caddesi No:7, Altındağ/Ankara',
      adresEN: 'Hipodrom Street No:7, Altındağ/Ankara',
      tip: 'Ana Merkez',
      tipEN: 'Main Center',
    ),
  ];

  Future<void> _openEgoSite() async {
    final uri = Uri.parse('https://www.ego.gov.tr/tr/birim/3/baskent-kart');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch URL');
    }
  }

  Future<void> _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              isEN ? 'Nearby Dealers' : 'Yakın Bayiler',
              style: const TextStyle(
                  color: AppColors.primaryNavy, fontWeight: FontWeight.w800),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primaryNavy, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser,
                    color: AppColors.primaryNavy),
                onPressed: _openEgoSite,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ─── Bilgi Banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00C853).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🏪', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEN
                            ? 'BaşkentKart sales points near Başkentray stations. Tap a location to open in Maps.'
                            : 'Başkentray hattı boyunca BaşkentKart satış noktaları. Haritada açmak için dokunun.',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Bayi Listesi ──────────────────────────────────────────
              ..._bayiler.map((b) => _buildBayiCard(b, isEN)),

              // ─── Tüm Satış Noktaları Butonu ────────────────────────────
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openEgoSite,
                icon: const Icon(Icons.open_in_browser),
                label: Text(
                    isEN ? 'All Sales Points (EGO Site)' : 'Tüm Satış Noktaları (EGO Sitesi)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.primaryNavy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBayiCard(_Bayi b, bool isEN) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF8D7DA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text('🏪', style: TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          isEN ? b.isimEN : b.isim,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isEN ? b.adresEN : b.adres,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isEN ? b.tipEN : b.tip,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.map_outlined,
              color: Color(0xFF2196F3), size: 22),
          onPressed: () => _openMaps(isEN ? b.adresEN : b.adres),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _Bayi {
  final String istasyon;
  final String isim;
  final String isimEN;
  final String adres;
  final String adresEN;
  final String tip;
  final String tipEN;

  const _Bayi({
    required this.istasyon,
    required this.isim,
    required this.isimEN,
    required this.adres,
    required this.adresEN,
    required this.tip,
    required this.tipEN,
  });
}
