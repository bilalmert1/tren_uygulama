import '../models/station.dart';
import 'time_service.dart';

class TrainTrackerService {
  static List<ActiveTrain> getActiveTrains() {
    final now = TimeService.nowTR();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final List<ActiveTrain> activeTrains = [];

    // Kayaş -> Sincan trenleri
    final kayasDepartures = Station.getKayasBaseDepartures(isWeekend);
    for (var depStr in kayasDepartures) {
      final depTime = _parseTime(depStr, now);
      final finishTime = depTime.add(const Duration(minutes: 49));

      if (now.isAfter(depTime) && now.isBefore(finishTime)) {
        activeTrains.add(_calculatePosition(depTime, TrainDirection.sincan));
      }
    }

    // Sincan -> Kayaş trenleri
    final sincanDepartures = Station.getSincanBaseDepartures(isWeekend);
    for (var depStr in sincanDepartures) {
      final depTime = _parseTime(depStr, now);
      final finishTime = depTime.add(const Duration(minutes: 49));

      if (now.isAfter(depTime) && now.isBefore(finishTime)) {
        activeTrains.add(_calculatePosition(depTime, TrainDirection.kayas));
      }
    }

    return activeTrains;
  }

  static DateTime _parseTime(String timeStr, DateTime reference) {
    final parts = timeStr.split(':');
    return DateTime(
      reference.year,
      reference.month,
      reference.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static ActiveTrain _calculatePosition(DateTime departureTime, TrainDirection direction) {
    final now = TimeService.nowTR();
    final elapsedMinutes = now.difference(departureTime).inSeconds / 60.0;
    
    final stations = Station.allStations;
    if (direction == TrainDirection.kayas) {
      // Sincan -> Kayaş (Geriye doğru liste)
      final reversedStations = stations.reversed.toList();
      return _interpolate(reversedStations, elapsedMinutes, direction);
    } else {
      // Kayaş -> Sincan (Normal liste)
      return _interpolate(stations, elapsedMinutes, direction);
    }
  }

  static ActiveTrain _interpolate(List<Station> route, double elapsed, TrainDirection direction) {
    for (int i = 0; i < route.length - 1; i++) {
      final s1 = route[i];
      final s2 = route[i + 1];
      
      final d1 = direction == TrainDirection.sincan ? s1.offsetFromKayas : s1.offsetFromSincan;
      final d2 = direction == TrainDirection.sincan ? s2.offsetFromKayas : s2.offsetFromSincan;

      if (elapsed >= d1 && elapsed <= d2) {
        final segmentDuration = (d2 - d1).toDouble();
        if (segmentDuration == 0) return ActiveTrain(lat: s1.latitude, lng: s1.longitude, direction: direction);
        
        final ratio = (elapsed - d1) / segmentDuration;
        final lat = s1.latitude + (s2.latitude - s1.latitude) * ratio;
        final lng = s1.longitude + (s2.longitude - s1.longitude) * ratio;
        
        return ActiveTrain(lat: lat, lng: lng, direction: direction);
      }
    }
    
    // Fallback
    return ActiveTrain(lat: route.last.latitude, lng: route.last.longitude, direction: direction);
  }
}

class ActiveTrain {
  final double lat;
  final double lng;
  final TrainDirection direction;

  ActiveTrain({required this.lat, required this.lng, required this.direction});
}
