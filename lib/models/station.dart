enum TrainDirection { kayas, sincan }

class Station {
  final String name;
  final double latitude;
  final double longitude;
  final int offsetFromKayas; // Kayaş'tan Sincan yönüne olan dakika farkı
  final int offsetFromSincan; // Sincan'dan Kayaş yönüne olan dakika farkı

  Station({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.offsetFromKayas,
    required this.offsetFromSincan,
  });

  /// Seçili yöne ve günün tarihine (haftaiçi/haftasonu) göre gerçek saatleri döndürür
  List<String> getTimes(TrainDirection direction) {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    if (direction == TrainDirection.kayas) {
      // Kayaş Yönü (Sincan ➔ Kayaş) - Sincan'dan kalkan ve Kayaş'a varan
      return _calculateStationTimes(getSincanBaseDepartures(isWeekend), offsetFromSincan);
    } else {
      // Sincan Yönü (Kayaş ➔ Sincan) - Kayaş'tan kalkan ve Sincan'a varan
      return _calculateStationTimes(getKayasBaseDepartures(isWeekend), offsetFromKayas);
    }
  }

  /// Yardımcı: Kalkış saatlerine istasyon ofsetini ekler
  List<String> _calculateStationTimes(List<String> baseTimes, int offset) {
    return baseTimes.map((timeStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final departure = DateTime(2024, 1, 1, hour, minute);
      final arrival = departure.add(Duration(minutes: offset));
      
      return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
    }).toList();
  }

  /// Kayaş'tan kalkan trenlerin listesi (Sincan yönü)
  static List<String> getKayasBaseDepartures(bool isWeekend) {
    List<String> times = [];
    
    // Sabah (Her gün)
    times.addAll(['06:00', '06:15', '06:30', '06:45', '07:00', '07:15', '07:30', '07:45', '08:00']);
    
    // Yoğun Saat Ekleri
    if (!isWeekend) {
      times.addAll(['08:10', '08:20']);
    } else {
      times.add('08:15');
    }
    
    // Gün İçi (Her 15 dk)
    _addInterval(times, '08:30', '21:00', 15);
    
    // Gece (Her 30 dk)
    times.addAll(['21:30', '22:00', '22:30', '23:00']);
    
    times.sort();
    return times;
  }

  /// Sincan'dan kalkan trenlerin listesi (Kayaş yönü)
  static List<String> getSincanBaseDepartures(bool isWeekend) {
    List<String> times = [];
    
    // Sabah (Her gün)
    times.addAll(['06:00', '06:15', '06:30', '06:45', '07:00', '07:30', '08:00']);
    
    // Yoğun Saat Ekleri
    if (!isWeekend) {
      times.addAll(['07:10', '07:20', '07:40', '07:50']);
    } else {
      times.addAll(['07:15', '07:45']);
    }
    
    // Gün İçi (Her 15 dk)
    _addInterval(times, '08:15', '21:00', 15);
    
    // Gece (Her 30 dk)
    times.addAll(['21:30', '22:00', '22:30', '23:00']);
    
    times.sort();
    return times;
  }

  static void _addInterval(List<String> list, String startStr, String endStr, int minutes) {
    final sp = startStr.split(':');
    final ep = endStr.split(':');
    DateTime curr = DateTime(2024, 1, 1, int.parse(sp[0]), int.parse(sp[1]));
    DateTime end = DateTime(2024, 1, 1, int.parse(ep[0]), int.parse(ep[1]));
    
    while (curr.isBefore(end) || curr.isAtSameMomentAs(end)) {
      list.add('${curr.hour.toString().padLeft(2, '0')}:${curr.minute.toString().padLeft(2, '0')}');
      curr = curr.add(Duration(minutes: minutes));
    }
  }

  static List<Station> get allStations => [
    Station(name: 'Kayaş', latitude: 39.913427, longitude: 32.965733, offsetFromKayas: 0, offsetFromSincan: 49),
    Station(name: 'Köstence', latitude: 39.916883, longitude: 32.950734, offsetFromKayas: 2, offsetFromSincan: 47),
    Station(name: 'Üreğil', latitude: 39.922501, longitude: 32.932175, offsetFromKayas: 4, offsetFromSincan: 45),
    Station(name: 'Bağderesi', latitude: 39.925907, longitude: 32.923281, offsetFromKayas: 5, offsetFromSincan: 44),
    Station(name: 'Mamak', latitude: 39.931551, longitude: 32.911275, offsetFromKayas: 7, offsetFromSincan: 42),
    Station(name: 'Saimekadın', latitude: 39.937516, longitude: 32.894731, offsetFromKayas: 9, offsetFromSincan: 40),
    Station(name: 'Demirlibahçe', latitude: 39.939860, longitude: 32.882919, offsetFromKayas: 11, offsetFromSincan: 38),
    Station(name: 'Cebeci', latitude: 39.933394, longitude: 32.876150, offsetFromKayas: 13, offsetFromSincan: 36),
    Station(name: 'Kurtuluş', latitude: 39.928904, longitude: 32.868185, offsetFromKayas: 15, offsetFromSincan: 34),
    Station(name: 'Yenişehir', latitude: 39.929097, longitude: 32.857802, offsetFromKayas: 16, offsetFromSincan: 33),
    Station(name: 'Ankara', latitude: 39.934823, longitude: 32.843533, offsetFromKayas: 20, offsetFromSincan: 29),
    Station(name: 'Hipodrom', latitude: 39.945130, longitude: 32.826066, offsetFromKayas: 23, offsetFromSincan: 26),
    Station(name: 'Gazi Mahallesi', latitude: 39.944176, longitude: 32.812730, offsetFromKayas: 25, offsetFromSincan: 24),
    Station(name: 'Gazi', latitude: 39.940203, longitude: 32.795917, offsetFromKayas: 27, offsetFromSincan: 22),
    Station(name: 'Motor Durağı', latitude: 39.934429, longitude: 32.778448, offsetFromKayas: 29, offsetFromSincan: 20),
    Station(name: 'Behiçbey', latitude: 39.931573, longitude: 32.749863, offsetFromKayas: 32, offsetFromSincan: 17),
    Station(name: 'Yıldırım', latitude: 39.932394, longitude: 32.704497, offsetFromKayas: 35, offsetFromSincan: 14),
    Station(name: 'Havadurağı', latitude: 39.942371, longitude: 32.688254, offsetFromKayas: 37, offsetFromSincan: 12),
    Station(name: 'Etimesgut', latitude: 39.949280, longitude: 32.662698, offsetFromKayas: 39, offsetFromSincan: 10),
    Station(name: 'Özgüneş', latitude: 39.951879, longitude: 32.648922, offsetFromKayas: 41, offsetFromSincan: 8),
    Station(name: 'Eryaman YHT', latitude: 39.955755, longitude: 32.630402, offsetFromKayas: 43, offsetFromSincan: 6),
    Station(name: 'Elvankent', latitude: 39.958793, longitude: 32.612221, offsetFromKayas: 45, offsetFromSincan: 4),
    Station(name: 'Lale', latitude: 39.961557, longitude: 32.598724, offsetFromKayas: 47, offsetFromSincan: 2),
    Station(name: 'Sincan', latitude: 39.964648, longitude: 32.583918, offsetFromKayas: 49, offsetFromSincan: 0),
  ];
}
