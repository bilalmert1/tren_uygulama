import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';

class BaskentKartScreen extends StatelessWidget {
  const BaskentKartScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Kart Görseli ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2A3A), Color(0xFF000000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.credit_card,
                              color: Colors.white, size: 36),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF00FF88), width: 0.5),
                            ),
                            child: const Text(
                              'EGO',
                              style: TextStyle(
                                  color: Color(0xFF00FF88),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BaşkentKart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEN
                            ? 'Ankara Integrated Transportation Card'
                            : 'Ankara Toplu Taşıma Kartı',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Hızlı Erişim Butonları ───────────────────────────────
                Text(
                  isEN ? 'QUICK ACCESS' : 'HIZLI ERİŞİM',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.account_balance_wallet_outlined,
                        label: isEN ? 'Check Balance' : 'Bakiye Sorgula',
                        color: const Color(0xFF00C853),
                        onTap: () => _launch('https://baskentulasim.com/guest-payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.add_card_outlined,
                        label: isEN ? 'Load Balance' : 'Bakiye Yükle',
                        color: const Color(0xFF2196F3),
                        onTap: () => _launch('https://baskentulasim.com/guest-payment'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.store_outlined,
                        label: isEN ? 'Sales Points' : 'Satış Noktaları',
                        color: const Color(0xFFFF9800),
                        onTap: () => _launch('https://baskentkart.ego.gov.tr/'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.report_problem_outlined,
                        label: isEN ? 'Lost/Stolen' : 'Kayıp/Çalıntı',
                        color: const Color(0xFFF44336),
                        onTap: () => _launch('https://www.ego.gov.tr/tr/kayip/kart'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Bilgi Kartı ──────────────────────────────────────────
                Text(
                  isEN ? 'CARD FEATURES' : 'KART ÖZELLİKLERİ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _featureRow(
                        icon: Icons.directions_bus,
                        title: isEN ? 'All EGO Buses' : 'Tüm EGO Otobüsleri',
                        subtitle: isEN
                            ? 'Valid on all EGO lines'
                            : 'Tüm EGO hatlarında geçerli',
                      ),
                      const Divider(height: 20),
                      _featureRow(
                        icon: Icons.train,
                        title: isEN ? 'Başkentray' : 'Başkentray',
                        subtitle: isEN
                            ? 'Sincan ↔ Kayaş suburban train'
                            : 'Sincan ↔ Kayaş banliyö treni',
                      ),
                      const Divider(height: 20),
                      _featureRow(
                        icon: Icons.subway,
                        title: isEN ? 'Metro Lines' : 'Metro Hatları',
                        subtitle: isEN
                            ? 'Ankara Metro (M1, M2, M3, M4)'
                            : 'Ankara Metrosu (M1, M2, M3, M4)',
                      ),
                      const Divider(height: 20),
                      _featureRow(
                        icon: Icons.sync_alt,
                        title: isEN ? 'Transfer Discount' : 'Aktarma İndirimi',
                        subtitle: isEN
                            ? 'Discounted price on transfers'
                            : 'Aktarmalarda indirimli ücret',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Resmi Site Butonu ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _launch('https://www.ego.gov.tr/tr/birim/3/baskent-kart'),
                    icon: const Icon(Icons.open_in_browser),
                    label: Text(
                        isEN ? 'Visit Official Site' : 'Resmi Siteye Git'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFF1A1A1A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
