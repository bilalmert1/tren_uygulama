import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../services/distance_service.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'detail_screen.dart';
import 'duyurular_screen.dart';
import 'station_search_screen.dart';
import 'yakin_bayiler_screen.dart';
import 'yakin_duraklar_screen.dart';
import 'sorun_bildir_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Station> _stations = Station.allStations;
  Station? _nearestStation;
  bool _isLoading = true;
  bool _isLocationActual = false; // Konum tam olarak doğrulandı mı?
  StreamSubscription<Position>? _positionSub;

  Station? _fromStation;
  Station? _toStation;

  bool _isDisposed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _startLocationStream();
    
    // Her 1 saniyede bir ekranı yenile (saniyelerin güncellenmesi için)
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  void _startLocationStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _isLocationActual = true; // Uydudan/Servisten veri geldi
        _nearestStation =
            DistanceService.findNearestStation(_stations, pos);
        _fromStation ??= _nearestStation;
        _isLoading = false;
      });
    });
  }

    Future<void> _refreshData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Konum izni kalıcı reddedilmişse kullanıcıyı bilgilendir
      if (await LocationService.isPermissionPermanentlyDenied()) {
        _isLocationActual = false;
        _nearestStation = _stations.firstWhere(
            (s) => s.name == 'Ankara',
            orElse: () => _stations[10]);
        _fromStation ??= _nearestStation;
        if (mounted) {
          setState(() => _isLoading = false);
          _showPermissionDialog();
        }
        return;
      }

      // Hızlıca son bilinen konumu al (bekletmeden)
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        _isLocationActual = true;
        _nearestStation = DistanceService.findNearestStation(_stations, pos);
      } else {
        _isLocationActual = false;
        // Varsayılan istasyon
        _nearestStation = _stations.firstWhere((s) => s.name == 'Ankara', orElse: () => _stations[10]);
      }
      _fromStation ??= _nearestStation;
    } catch (e) {
      _isLocationActual = false;
      _nearestStation = _stations.firstWhere((s) => s.name == 'Ankara', orElse: () => _stations[10]);
      _fromStation ??= _nearestStation;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showPermissionDialog() {
    final isEN = AppState.instance.locale.languageCode == 'en';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEN ? 'Location Permission' : 'Konum İzni'),
        content: Text(isEN
            ? 'Location permission is permanently denied. Please enable it from Settings to find your nearest station.'
            : 'Konum izni kalıcı olarak reddedildi. En yakın durağı bulmak için Ayarlar\'dan izin verin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEN ? 'Cancel' : 'İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              LocationService.openSettings();
            },
            child: Text(isEN ? 'Open Settings' : 'Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  TrainDirection get _routeDirection {
    if (_fromStation == null || _toStation == null) return TrainDirection.kayas;
    final fi = _stations.indexOf(_fromStation!);
    final ti = _stations.indexOf(_toStation!);
    // ti (hedef) fi'den (başlangıç) küçükse, listenin başına (Kayaş'a) gidiyoruz demektir.
    return ti < fi ? TrainDirection.kayas : TrainDirection.sincan;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryBlue,
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryBlue)),
                  )
                else ...[
                  _buildNearestStation(isEN),
                  _buildRoutePlanner(isEN),
                  _buildSectionTitle(
                      isEN ? 'Quick Access' : 'Hızlı Erişim', isEN),
                  _buildQuickGrid(isEN),
                ],
              ],
            ),
          ),
        );
      },
    );
  }


  // ─── En Yakın Durak ──────────────────────────────────────────────────────
  Widget _buildNearestStation(bool isEN) {
    if (_nearestStation == null) return const SliverToBoxAdapter(child: SizedBox());

    final nextKayas =
        TimeService.getNextTrainTime(_nearestStation!.getTimes(TrainDirection.kayas));
    final nextSincan =
        TimeService.getNextTrainTime(_nearestStation!.getTimes(TrainDirection.sincan));
    
    // Terminal istasyon kontrolü: Kayaş'ta isek Kayaş yönünü (varış), Sincan'da isek Sincan yönünü (varış) gösterme.
    final showKayas = _nearestStation!.name != 'Kayaş';
    final showSincan = _nearestStation!.name != 'Sincan';

    final textKayas = TimeService.formatRemainingTime(nextKayas, isEN);
    final textSincan = TimeService.formatRemainingTime(nextSincan, isEN);

    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              station: _nearestStation!,
              initialDirection: (!showKayas || (_nearestStation!.name != 'Sincan' && nextKayas.isBefore(nextSincan)))
                  ? TrainDirection.kayas
                  : TrainDirection.sincan,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryNavy, AppColors.primaryBlue],
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
                  Text(
                    isEN ? 'NEAREST STOP' : 'SİZE EN YAKIN DURAK',
                    style: const TextStyle(
                      color: AppColors.lightBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isLocationActual 
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.accentYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isLocationActual ? AppColors.success : AppColors.accentYellow,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLocationActual ? Icons.location_on : Icons.location_searching,
                          color: _isLocationActual ? AppColors.success : AppColors.accentYellow,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLocationActual 
                              ? (isEN ? 'ACTUAL' : 'GERÇEK KONUM')
                              : (isEN ? 'LOCATING...' : 'KONUM ARANIYOR...'),
                          style: TextStyle(
                            color: _isLocationActual ? AppColors.success : AppColors.accentYellow,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _nearestStation!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (showKayas)
                    Expanded(
                      child: _directionMinCard(
                        label: '← Kayaş',
                        timeStr: textKayas,
                        accent: AppColors.accentYellow,
                      ),
                    ),
                  if (showKayas && showSincan) const SizedBox(width: 10),
                  if (showSincan)
                    Expanded(
                      child: _directionMinCard(
                        label: 'Sincan →',
                        timeStr: textSincan,
                        accent: AppColors.lightBlue,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _directionMinCard(
      {required String label, required String timeStr, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: TextStyle(
              color: accent,
              fontSize: 20, // Biraz küçüldü çünkü "X sa Y dk" gelince sığmayabilir
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rota Hesaplama ──────────────────────────────────────────────────────
  Widget _buildRoutePlanner(bool isEN) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEN ? 'ROUTE PLANNER' : 'ROTA HESAPLAMA',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _stationDropdown(isEN, true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Icon(Icons.train,
                          color: AppColors.primaryNavy.withOpacity(0.6),
                          size: 26),
                    ],
                  ),
                ),
                Expanded(child: _stationDropdown(isEN, false)),
              ],
            ),
            if (_fromStation != null &&
                _toStation != null &&
                _fromStation != _toStation) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: AppColors.backgroundLight),
              ),
              _buildTripDetails(isEN),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stationDropdown(bool isEN, bool isFrom) {
    final value = isFrom ? _fromStation : _toStation;
    final label = isFrom ? (isEN ? 'FROM' : 'NEREDEN') : (isEN ? 'TO' : 'NEREYE');

    return Column(
      crossAxisAlignment:
          isFrom ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMedium, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<Station>(
            isExpanded: true,
            alignment: isFrom ? Alignment.centerLeft : Alignment.centerRight,
            value: value,
            hint: Text(isEN ? 'Select' : 'Seç',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMedium, size: 18),
            style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 15,
                fontWeight: FontWeight.bold),
            items: _stations
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() {
              if (isFrom) {
                _fromStation = val;
                if (_fromStation == _toStation) _toStation = null;
              } else {
                _toStation = val;
                if (_toStation == _fromStation) _fromStation = null;
              }
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails(bool isEN) {
    final dir = _routeDirection;
    final nextTime =
        TimeService.getNextTrainTime(_fromStation!.getTimes(dir));
    final textLeft = TimeService.formatRemainingTime(nextTime, isEN);
    final journeyDur = TimeService.getJourneyDuration(
        _fromStation!.getTimes(dir), _toStation!.getTimes(dir));
    final arrivalTime = nextTime.add(Duration(minutes: journeyDur));

    final nextStr =
        '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';
    final arrStr =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailScreen(station: _fromStation!, initialDirection: dir),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tripInfoCol(
            isEN ? 'Next Train' : 'Sonraki Tren',
            nextStr,
            textLeft,
            AppColors.primaryBlue,
          ),
          Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
          _tripInfoCol(
            isEN ? 'Est. Arrival' : 'Tahmini Varış',
            arrStr,
            '~$journeyDur ${isEN ? 'min' : 'dk sürecek'}',
            AppColors.textMedium,
          ),
        ],
      ),
    );
  }

  Widget _tripInfoCol(
      String label, String time, String sub, Color subColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
        const SizedBox(height: 4),
        Text(time,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.primaryNavy)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: subColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(sub,
              style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ─── Bölüm Başlığı ───────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, bool isEN) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ─── 6'lı Hızlı Erişim Grid ──────────────────────────────────────────────
  Widget _buildQuickGrid(bool isEN) {
    final cards = [
      _QuickCardData(
        emoji: '📢',
        title: isEN ? 'Announcements' : 'Duyurular',
        bg: const Color(0xFFFFF3CD),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DuyurularScreen())),
      ),
      _QuickCardData(
        emoji: '🔍',
        title: isEN ? 'Find Stop' : 'Durak Ara',
        bg: const Color(0xFFD1ECF1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationSearchScreen(
                title: isEN ? 'Find Stop' : 'Durak Ara'),
          ),
        ),
      ),
      _QuickCardData(
        emoji: '🚆',
        title: isEN ? 'Lines &\nSchedules' : 'Hat ve\nSeferler',
        bg: const Color(0xFFD4EDDA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationSearchScreen(
                title: isEN ? 'Lines & Schedules' : 'Hat ve Seferler'),
          ),
        ),
      ),
      _QuickCardData(
        emoji: '🏪',
        title: isEN ? 'Nearby\nDealers' : 'Yakın\nBayiler',
        bg: const Color(0xFFF8D7DA),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const YakinBayilerScreen())),
      ),
      _QuickCardData(
        emoji: '📍',
        title: isEN ? 'Nearby\nStops' : 'Yakın\nDuraklar',
        bg: const Color(0xFFE2D9F3),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const YakinDurakScreen())),
      ),
      _QuickCardData(
        emoji: '🚨',
        title: isEN ? 'Report\nIssue' : 'Sorun\nBildir',
        bg: const Color(0xFFFFE5D0),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SorunBildirScreen())),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) {
            final c = cards[i];
            return GestureDetector(
              onTap: c.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 8),
                    Text(
                      c.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickCardData {
  final String emoji;
  final String title;
  final Color bg;
  final VoidCallback onTap;
  _QuickCardData(
      {required this.emoji,
      required this.title,
      required this.bg,
      required this.onTap});
}
