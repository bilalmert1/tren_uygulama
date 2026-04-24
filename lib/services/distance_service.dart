import 'package:geolocator/geolocator.dart';
import '../models/station.dart';

class DistanceService {
  /// Kullanıcının konumuna en yakın durağı bulur
  static Station findNearestStation(List<Station> stations, Position userPosition) {
    Station nearest = stations.first;
    double minDistance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      nearest.latitude,
      nearest.longitude,
    );

    for (int i = 1; i < stations.length; i++) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        stations[i].latitude,
        stations[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = stations[i];
      }
    }

    return nearest;
  }
}
