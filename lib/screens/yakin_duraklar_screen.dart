import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../providers/app_state.dart';
import 'detail_screen.dart';

class YakinDurakScreen extends StatefulWidget {
  const YakinDurakScreen({super.key});

  @override
  State<YakinDurakScreen> createState() => _YakinDurakScreenState();
}

class _YakinDurakScreenState extends State<YakinDurakScreen> {
  List<MapEntry<Station, double>> _sortedStations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final position = await LocationService.getCurrentPosition();
    final stations = Station.allStations;

    if (position != null) {
      final routeList = stations.map((s) {
        final dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          s.latitude,
          s.longitude,
        );
        return MapEntry(s, dist);
      }).toList();
      // Mesafeye göre küçükten büyüğe sırala
      routeList.sort((a, b) => a.value.compareTo(b.value));

      if (mounted) {
        setState(() {
          _sortedStations = routeList;
          _isLoading = false;
        });
      }
    } else {
      // Konum alınamadığında da hat sırası korunur
      if (mounted) {
        setState(() {
          _sortedStations = stations.map((s) => MapEntry(s, -1.0)).toList();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 0) return '';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';
        
        // En yakın durağı bul
        MapEntry<Station, double>? nearestEntry;
        if (_sortedStations.isNotEmpty) {
          // Eğer konum varsa gerçek en yakını bul
          if (_sortedStations.any((e) => e.value >= 0)) {
            nearestEntry = _sortedStations.reduce((a, b) => 
              (a.value >= 0 && (b.value < 0 || a.value < b.value)) ? a : b);
          } else {
            // Konum yoksa Ana Sayfa ile senkron: Ankara'yı seç
            try {
              nearestEntry = _sortedStations.firstWhere((e) => e.key.name == 'Ankara');
            } catch (_) {
              nearestEntry = _sortedStations.first;
            }
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
                )
              : RefreshIndicator(
                  onRefresh: _loadStations,
                  color: const Color(0xFF1A1A1A),
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(context, isEN),
                      if (nearestEntry != null) _buildNearestStationCard(nearestEntry, isEN),
                      _buildSectionTitle(isEN ? 'All Stations' : 'Tüm Duraklar'),
                      _buildStationList(isEN),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, bool isEN) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isEN ? 'Find Stop' : 'Durak Bul',
        style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );
  }

  Widget _buildNearestStationCard(MapEntry<Station, double> entry, bool isEN) {
    final station = entry.key;
    final distance = entry.value;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location, color: Color(0xFF00FF88), size: 16),
                const SizedBox(width: 8),
                Text(
                  isEN ? 'NEAREST TO YOU' : 'SİZE EN YAKIN DURAK',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              station.name,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (distance >= 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDistance(distance),
                  style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToDetail(station),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(isEN ? 'View Details' : 'Detayları Gör'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildStationList(bool isEN) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = _sortedStations[index];
            final station = entry.key;
            final distance = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                onTap: () => _navigateToDetail(station),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Icon(Icons.train_outlined, color: Color(0xFF1A1A1A), size: 18)),
                ),
                title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(
                  distance >= 0 ? _formatDistance(distance) : (isEN ? 'Locating...' : 'Konum aranıyor...'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black12),
              ),
            );
          },
          childCount: _sortedStations.length,
        ),
      ),
    );
  }

  void _navigateToDetail(Station station) {
    // Akıllı yön seçimi: Hangi yöndeki tren daha yakınsa o yönü aç
    final nextKayas = station.getTimes(TrainDirection.kayas).isNotEmpty 
      ? TimeService.getNextTrainTime(station.getTimes(TrainDirection.kayas)) 
      : DateTime.now().add(const Duration(hours: 10));
    final nextSincan = station.getTimes(TrainDirection.sincan).isNotEmpty 
      ? TimeService.getNextTrainTime(station.getTimes(TrainDirection.sincan)) 
      : DateTime.now().add(const Duration(hours: 10));

    final diffKayas = TimeService.calculateMinutesDifference(DateTime.now(), nextKayas);
    final diffSincan = TimeService.calculateMinutesDifference(DateTime.now(), nextSincan);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          station: station,
          initialDirection: diffKayas <= diffSincan 
              ? TrainDirection.kayas 
              : TrainDirection.sincan,
        ),
      ),
    );
  }
}
