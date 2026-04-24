import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Mevcut konumu döndürür. null dönerse konum alınamadı demektir.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Servis kontrolü
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) {
      // İzin kalıcı olarak reddedildi — null dön, UI tarafı bilgilendirir
      return null;
    }

    try {
      // Önce son bilinen konumu dene (hızlı)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) return lastPosition;

      // Gerçek zamanlı konum (15 sn timeout)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Konum izni kalıcı olarak reddedilmişse true döner
  static Future<bool> isPermissionPermanentlyDenied() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// Uygulama ayarlarını açar (izin yönetimi için)
  static Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Sürekli konum akışı (harita ve ana ekran için)
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 metrede bir güncelleme
      ),
    );
  }
}
