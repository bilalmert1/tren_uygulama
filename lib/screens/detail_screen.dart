import 'dart:async';
import 'package:flutter/material.dart';
import '../models/station.dart';
import '../services/time_service.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final Station station;
  final TrainDirection? initialDirection;

  const DetailScreen({super.key, required this.station, this.initialDirection});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TrainDirection? _selectedDirection;

  bool _isDisposed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    if (widget.station.name == 'Kayaş') {
      _selectedDirection = TrainDirection.sincan;
    } else if (widget.station.name == 'Sincan') {
      _selectedDirection = TrainDirection.kayas;
    } else if (widget.initialDirection != null) {
      _selectedDirection = widget.initialDirection;
    } else {
      // Akıllı yön seçimi: Hiçbir yön belirtilmemişse en yakın olanı seç
      final nextKayas = widget.station.getTimes(TrainDirection.kayas).isNotEmpty 
        ? TimeService.getNextTrainTime(widget.station.getTimes(TrainDirection.kayas)) 
        : DateTime.now().add(const Duration(hours: 10));
      final nextSincan = widget.station.getTimes(TrainDirection.sincan).isNotEmpty 
        ? TimeService.getNextTrainTime(widget.station.getTimes(TrainDirection.sincan)) 
        : DateTime.now().add(const Duration(hours: 10));

      final diffKayas = TimeService.calculateMinutesDifference(DateTime.now(), nextKayas);
      final diffSincan = TimeService.calculateMinutesDifference(DateTime.now(), nextSincan);

      _selectedDirection = diffKayas <= diffSincan 
          ? TrainDirection.kayas 
          : TrainDirection.sincan;
    }
    
    // Her 1 saniyede bir ekranı yenile
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isEN = AppState.instance.locale.languageCode == 'en';
        final isFav = AppState.instance.isFavorite(widget.station.name);

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, isFav, isEN),
              _buildDirectionSelection(isEN),
              if (_selectedDirection != null) ...[
                _buildNextTrainCard(isEN),
                _buildTimeListHeader(isEN),
                _buildTimeList(isEN),
              ] else
                _buildNoSelectionState(isEN),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isFav, bool isEN) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryNavy,
      centerTitle: true, // Başlık ortalı
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFav ? Icons.star : Icons.star_outline,
            color: isFav ? Colors.amber : Colors.white,
            size: 26,
          ),
          onPressed: () => AppState.instance.toggleFavorite(widget.station.name),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          widget.station.name.toUpperCase(), // Büyük harf
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        background: Container(color: AppColors.primaryNavy),
      ),
    );
  }

  Widget _buildDirectionSelection(bool isEN) {
    // Kayaş veya Sincan ise yön seçimi gösterme (Tek yön var)
    if (widget.station.name == 'Kayaş' || widget.station.name == 'Sincan') {
      return const SliverToBoxAdapter(child: SizedBox(height: 10));
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: AppColors.primaryNavy,
        child: Column(
          children: [
            Row(
              children: [
                _dirButton(
                  label: isEN ? 'Kayaş Dir.' : 'Kayaş Yönü',
                  dir: TrainDirection.kayas, // Düzeltildi
                  isEN: isEN,
                ),
                const SizedBox(width: 12),
                _dirButton(
                  label: isEN ? 'Sincan Dir.' : 'Sincan Yönü',
                  dir: TrainDirection.sincan, // Düzeltildi
                  isEN: isEN,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _dirButton({
    required String label,
    required TrainDirection dir,
    required bool isEN,
  }) {
    final isSelected = _selectedDirection == dir;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDirection = dir),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentYellow : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? null : Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primaryNavy : Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSelectionState(bool isEN) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_transit_outlined, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              isEN ? 'Please select a direction' : 'Lütfen bir yön seçiniz',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEN ? 'to see train schedule' : 'tren saatlerini görmek için',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// Yenilenmiş "Premium" Dakika Gösterim Kartı
  Widget _buildNextTrainCard(bool isEN) {
    if (_selectedDirection == null) return const SliverToBoxAdapter();

    final times = widget.station.getTimes(_selectedDirection!);
    final nextTime = TimeService.getNextTrainTime(times);
    final timeStr = TimeService.formatRemainingTime(nextTime, isEN);
    final nextTimeStr =
        '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';

    final destName = _selectedDirection == TrainDirection.kayas ? 'Kayaş' : 'Sincan';

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            // Dinamik Yön Göstergesi Çubuğu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stationLabel(widget.station.name, Colors.white70),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, color: Colors.white12, size: 14),
                  ),
                  _trainIconWithDirection(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, color: Colors.white12, size: 14),
                  ),
                  _stationLabel(destName, AppColors.accentYellow),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Modern Dakika Gösterimi
            Stack(
              alignment: Alignment.center,
              children: [
                // Arka plan halka efekti
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentYellow.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Süre Metni
                Column(
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: timeStr.contains(' ') ? 38 : 72, // Uzunluğa göre punto ayarı
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEN ? 'REMAINING' : 'KALAN SÜRE',
                      style: const TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Kalkış Saati Chip'i
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled, color: Colors.white60, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    '${isEN ? 'Departure' : 'Kalkış'}: ',
                    style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    nextTimeStr,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationLabel(String name, Color color) {
    return Text(
      name,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _trainIconWithDirection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentYellow.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Transform.flip(
        flipX: _selectedDirection == TrainDirection.sincan,
        child: const Icon(Icons.train, color: AppColors.accentYellow, size: 18),
      ),
    );
  }

  Widget _buildTimeListHeader(bool isEN) {
    if (_selectedDirection == null) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEN ? 'DAILY SCHEDULE' : 'GÜNLÜK SEFERLER',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeList(bool isEN) {
    if (_selectedDirection == null) return const SliverToBoxAdapter();
    final times = widget.station.getTimes(_selectedDirection!);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final time = times[index];
            final now = TimeService.nowTR();
            final parts = time.split(':');
            final target = DateTime(
                now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
            final isPassed = target.isBefore(now);
            
            return Container(
              decoration: BoxDecoration(
                color: isPassed ? const Color(0xFFF1F3F5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPassed ? Colors.transparent : const Color(0xFFE9ECEF),
                  width: 1.5,
                ),
                boxShadow: isPassed ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                time,
                style: TextStyle(
                  color: isPassed ? AppColors.textMedium : AppColors.primaryNavy,
                  fontWeight: isPassed ? FontWeight.w500 : FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            );
          },
          childCount: times.length,
        ),
      ),
    );
  }
}
