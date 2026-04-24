import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class DuyurularScreen extends StatelessWidget {
  const DuyurularScreen({super.key});

  static final List<_Duyuru> _duyurular = [
    _Duyuru(
      tarih: '2025-04',
      baslik: 'Başkentray Sefer Saatleri',
      baslikEN: 'Başkentray Schedule',
      icerik:
          'Başkentray hattı (Sincan–Kayaş) hafta içi ve hafta sonu farklı saat dilimlerinde çalışmaktadır. '
          'Sabah 06:00\'dan gece 23:00\'e kadar düzenli sefer yapılmaktadır.',
      icerikEN:
          'Başkentray line (Sincan–Kayaş) operates on weekdays and weekends with different schedules. '
          'Regular service from 06:00 to 23:00.',
      icon: Icons.schedule,
      color: Color(0xFF2196F3),
    ),
    _Duyuru(
      tarih: '2025-03',
      baslik: 'BaşkentKart ile Seyahat',
      baslikEN: 'Travel with BaşkentKart',
      icerik:
          'Başkentray trenleri BaşkentKart ile kullanılabilmektedir. '
          'Nakit ile bilet satışı yapılmamaktadır.',
      icerikEN:
          'Başkentray trains can be used with BaşkentKart. '
          'Ticket sales with cash are not available.',
      icon: Icons.credit_card,
      color: Color(0xFF00C853),
    ),
    _Duyuru(
      tarih: '2025-02',
      baslik: 'Aktarma Noktaları',
      baslikEN: 'Transfer Points',
      icerik:
          'Ankara Garı, Hipodrom ve Etimesgut istasyonlarında metro ve otobüs hatlarına aktarma yapılabilmektedir.',
      icerikEN:
          'Transfers to metro and bus lines are available at Ankara Garı, Hipodrom and Etimesgut stations.',
      icon: Icons.swap_horiz,
      color: Color(0xFFFF9800),
    ),
    _Duyuru(
      tarih: '2025-01',
      baslik: 'Yolcu Kapasitesi',
      baslikEN: 'Passenger Capacity',
      icerik:
          'Başkentray\'da her sefer yaklaşık 500-700 yolcu taşıyabilmektedir. '
          'Yoğun saatlerde seyahat planlamak için uygulamamızı kullanın.',
      icerikEN:
          'Each Başkentray service can carry approximately 500–700 passengers. '
          'Use our app to plan travel during peak hours.',
      icon: Icons.people_outline,
      color: Color(0xFF9C27B0),
    ),
  ];

  Future<void> _openOfficialSite() async {
    final uri = Uri.parse('https://www.tcddtasimacilik.gov.tr/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch URL');
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
              isEN ? 'Announcements' : 'Duyurular',
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
                tooltip: isEN ? 'Official Site' : 'Resmi Site',
                onPressed: _openOfficialSite,
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
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('📢', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEN
                            ? 'For up-to-date announcements, visit the official TCDD website.'
                            : 'Güncel duyurular için resmi TCDD sitesini ziyaret edebilirsiniz.',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF856404)),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Duyuru Listesi ────────────────────────────────────────
              ..._duyurular.map((d) => _buildDuyuruCard(d, isEN)),

              // ─── Resmi Site Butonu ─────────────────────────────────────
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openOfficialSite,
                icon: const Icon(Icons.open_in_browser),
                label: Text(isEN
                    ? 'More Announcements (Official Site)'
                    : 'Daha Fazla Duyuru (Resmi Site)'),
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

  Widget _buildDuyuruCard(_Duyuru d, bool isEN) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: d.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(d.icon, color: d.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEN ? d.baslikEN : d.baslik,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                    Text(
                      d.tarih,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isEN ? d.icerikEN : d.icerik,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Duyuru {
  final String tarih;
  final String baslik;
  final String baslikEN;
  final String icerik;
  final String icerikEN;
  final IconData icon;
  final Color color;

  const _Duyuru({
    required this.tarih,
    required this.baslik,
    required this.baslikEN,
    required this.icerik,
    required this.icerikEN,
    required this.icon,
    required this.color,
  });
}
