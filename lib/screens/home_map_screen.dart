import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../models/station.dart';
import '../services/train_tracker_service.dart';
import '../services/location_service.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../data/baskentray_route.dart';
import 'detail_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();
  List<ActiveTrain> _activeTrains = [];
  Timer? _trackerTimer;
  LatLng? _userLocation;
  double? _userHeading;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _updateTrains();
    _trackerTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateTrains());
    _getUserLocation();
  }

  @override
  void dispose() {
    _trackerTimer?.cancel();
    _positionSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    _positionSub = LocationService.getPositionStream().listen((pos) {
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        // Eğer cihazda pusula yoksa ve hareket halindeyse GPS yönünü kullan
        if (pos.heading > 0) {
          _userHeading = pos.heading;
        }
      });
    });

    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      setState(() => _userHeading = event.heading);
    });
  }

  void _updateTrains() {
    if (!mounted) return;
    setState(() => _activeTrains = TrainTrackerService.getActiveTrains());
  }

  Future<void> _getUserLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted && pos != null) {
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        setState(() => _userLocation = userLatLng);
        // Harita hazırsa kullanıcı konumuna odaklan
        if (_mapReady) {
          _mapController.move(userLatLng, 15.0);
        }
      }
      _startLocationTracking();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';

        return Scaffold(
          body: Stack(
            children: [
              // ─── HARİTA KATMANI ───────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation ?? const LatLng(39.9333, 32.8597),
                  initialZoom: 12.0,
                  maxZoom: 18.0,
                  minZoom: 10.0,
                  onMapReady: () {
                    _mapReady = true;
                    // Harita yüklendikten sonra konum varsa oraya git
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15.0);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  // ─── TREN RAYI (Polyline) ──────────────────────────────
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: BaskentrayRoute.points,
                        color: AppColors.primaryBlue.withOpacity(0.6),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                  // ─── İSTASYON İŞARETÇİLERİ ───────────────────────────
                  MarkerLayer(
                    markers: Station.allStations.map((s) {
                      return Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 100,
                        height: 60,
                        rotate: true,
                        child: GestureDetector(
                          onTap: () => _navigateToDetail(s),
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4)
                                  ],
                                ),
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // ─── AKTİF TRENLER ────────────────────────────────────
                  MarkerLayer(
                    markers: _activeTrains.map((train) {
                      return Marker(
                        point: LatLng(train.lat, train.lng),
                        width: 100,
                        height: 50,
                        rotate: true,
                        child: _buildTrainMarker(train, isEN),
                      );
                    }).toList(),
                  ),
                  // ─── KULLANICI KONUMU ──────────────────────────────────
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 120,
                          height: 120,
                          child: _buildUserLocationMarker(),
                        ),
                      ],
                    ),
                ],
              ),

              // ─── ÜST BİLGİ PANELİ ────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        isEN
                            ? 'Active Trains: ${_activeTrains.length}'
                            : 'Seyir Halindeki Tren: ${_activeTrains.length}',
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── KONUMA DÖN BUTONU ────────────────────────────────────
              if (_userLocation != null)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.primaryNavy,
                    onPressed: () => _mapController.move(_userLocation!, 15.0),
                    child: const Icon(Icons.my_location,
                        color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Google Maps tarzı kullanıcı konum marker'ı
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ─── PUSULA KONİSİ ─────────────────────────────────────────
        if (_userHeading != null)
          Transform.rotate(
            // Telefonun baktığı yön (kuzeye göre derece) → radyana çevir
            angle: _userHeading! * (math.pi / 180),
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _DirectionConePainter(),
            ),
          ),
        // ─── DIŞ HALKA ─────────────────────────────────────────────
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // ─── İÇ MAVİ NOKTA ─────────────────────────────────────────
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4285F4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainMarker(ActiveTrain train, bool isEN) {
    final isSincan = train.direction == TrainDirection.sincan;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.accentYellow, width: 0.5),
          ),
          child: Text(
            isSincan
                ? (isEN ? '→ Sincan' : 'Sincan\'a Gidiyor')
                : (isEN ? '← Kayaş' : 'Kayaş\'a Gidiyor'),
            style: const TextStyle(
                color: AppColors.accentYellow,
                fontSize: 8,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentYellow.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.train, size: 14, color: AppColors.primaryNavy),
              ),
            ),
            Positioned(
              right: isSincan ? -12 : null,
              left: !isSincan ? -12 : null,
              child: Icon(
                isSincan ? Icons.arrow_right : Icons.arrow_left,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToDetail(Station station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(station: station),
      ),
    );
  }


}

/// Google Maps tarzı yön konisi
/// - Tepe noktası tam mavi noktanın merkezinde (size.center)
/// - Yukarıya doğru eşkenar üçgen şeklinde açılır
/// - Merkezden uzaklaştıkça şeffaflaşan mavi gradient
class _DirectionConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Koninin boyutları
    const double coneHeight = 50.0; // Merkezden ne kadar uzağa gidecek
    const double halfBase = 28.0;   // Tabanın yarı genişliği

    // Gradient: tepe noktasında (merkez) opak, tabanda şeffaf
    final rect = Rect.fromLTRB(
      cx - halfBase,
      cy - coneHeight,
      cx + halfBase,
      cy,
    );

    final paint = ui.Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter, // Tepe noktası (merkez)
        end: Alignment.topCenter,      // Taban (uzak uç)
        colors: [
          Color(0x884285F4), // Opak mavi (tepe)
          Color(0x004285F4), // Şeffaf (taban)
        ],
      ).createShader(rect);

    final path = ui.Path()
      ..moveTo(cx, cy)                        // Tepe: mavi noktanın merkezi
      ..lineTo(cx - halfBase, cy - coneHeight) // Sol taban köşesi
      ..lineTo(cx + halfBase, cy - coneHeight) // Sağ taban köşesi
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionConePainter oldDelegate) => false;
  // Shape değişmez; sadece Transform.rotate dönüş açısını güncelliyor.
}
