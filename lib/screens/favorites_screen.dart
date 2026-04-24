import 'package:flutter/material.dart';
import '../models/station.dart';
import '../providers/app_state.dart';
import '../services/time_service.dart';
import '../services/time_service.dart';
import '../theme/app_colors.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';
        final favNames = AppState.instance.favoriteStationNames;
        final allStations = Station.allStations;
        final displayed = allStations.where((s) => favNames.contains(s.name)).toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Column(
            children: [
              const SizedBox(height: 12),
              // ─── Favori Listesi ───────────────────────────────────────────
              Expanded(
                child: displayed.isEmpty
                    ? _buildEmptyState(isEN)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayed.length,
                        itemBuilder: (context, index) {
                          final station = displayed[index];
                          return Dismissible(
                            key: Key('fav_${station.name}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              AppState.instance.toggleFavorite(station.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${station.name} ${isEN ? 'removed from favorites' : 'favorilerden silindi'}'),
                                  backgroundColor: AppColors.primaryNavy,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.only(right: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            child: _buildFavoriteCard(context, station, isEN),
                          );
                        },
                      ),
              ),

              // ─── Durak Ekle Butonu ────────────────────────────────────────
              _buildAddButton(context, isEN, allStations),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isEN) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEN ? 'No favorite stations yet.' : 'Favori durak bulunmuyor.',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            isEN ? 'Tap ⭐ in station search to add.' : 'Durak aramada ⭐ kullanarak ekleyin.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Station station, bool isEN) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('⭐', style: TextStyle(fontSize: 22))),
        ),
        title: Text(
          station.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          isEN ? 'Quick access to schedules' : 'Seferlere hızlı erişim',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // AKILLI YÖN SEÇİMİ: O an hangi tren daha yakınsa o yönü aç
          final nextKayas = TimeService.getNextTrainTime(station.getTimes(TrainDirection.kayas));
          final nextSincan = TimeService.getNextTrainTime(station.getTimes(TrainDirection.sincan));
          final minsKayas = TimeService.calculateMinutesDifference(TimeService.nowTR(), nextKayas);
          final minsSincan = TimeService.calculateMinutesDifference(TimeService.nowTR(), nextSincan);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(
                station: station,
                initialDirection: minsKayas <= minsSincan ? TrainDirection.kayas : TrainDirection.sincan,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isEN, List<Station> allStations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ElevatedButton.icon(
        onPressed: () => _showAddStationSheet(context, isEN, allStations),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(isEN ? 'Add More' : '+ Yeni Durak Ekle'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showAddStationSheet(BuildContext context, bool isEN, List<Station> allStations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(isEN ? 'Select Station' : 'Durak Seç',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(isEN ? 'Done' : 'Tamam')),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListenableBuilder(
                  listenable: AppState.instance,
                  builder: (context, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: allStations.length,
                      itemBuilder: (context, index) {
                        final station = allStations[index];
                        final isFav = AppState.instance.isFavorite(station.name);
                        return ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isFav ? AppColors.accentYellow.withOpacity(0.12) : AppColors.primaryBlue.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(Icons.train, size: 16, color: isFav ? AppColors.accentYellow : AppColors.primaryBlue),
                            ),
                          ),
                          title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Icon(isFav ? Icons.star : Icons.star_outline, color: isFav ? Colors.amber : Colors.grey[400], size: 22),
                          onTap: () => AppState.instance.toggleFavorite(station.name),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
