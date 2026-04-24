
class TimeService {
  /// Sistem yerel saatini döndürür (Fiziksel cihazlarda en güvenilir yöntem)
  static DateTime nowTR() {
    return DateTime.now();
  }

  /// Bir sonraki tren vaktini bulur.
  static DateTime getNextTrainTime(List<String> times) {
    if (times.isEmpty) return nowTR().add(const Duration(hours: 1));
    
    final now = nowTR();
    
    // 1. Bugünün kalan saatlerine bak
    for (String timeStr in times) {
      final parts = timeStr.split(':');
      final target = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // EĞER hedef saat 23:00'ten sonra kalkan bir trenin 00:XX varışı ise 
      // ve şu an akşam saatleriysek (örn 21:00+), bu hedefi yarına ötele.
      // (Örn: 23:30 kalkışlı trenin 00:20 varışı bugünün 00:20'si değil yarının 00:20'sidir)
      var effectiveTarget = target;
      if (target.hour < 4 && now.hour > 18) {
        effectiveTarget = target.add(const Duration(days: 1));
      }

      if (effectiveTarget.isAfter(now)) {
        return effectiveTarget;
      }
    }

    // 2. Eğer bugünkü listede hiç gelecek tren yoksa, listenin başındakini YARININ ilk treni kabul et
    final parts = times.first.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// İki tarih arasındaki dakika farkını hesaplar
  static int calculateMinutesDifference(DateTime now, DateTime target) {
    return target.difference(now).inMinutes;
  }

  /// Kalan süreyi kullanıcı dostu formatta döndürür.
  /// 60 dk'dan fazlaysa: "1 sa 20 dk"
  /// 1 dk'dan azsa: "45 sn" (Saniye bazlı geri sayım)
  /// Diğer durumlarda: "5 dk"
  static String formatRemainingTime(DateTime target, bool isEN) {
    final now = nowTR();
    final diff = target.difference(now);
    
    if (diff.isNegative) return isEN ? 'Departed' : 'Kalktı';
    
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;

    if (hours > 0) {
      if (isEN) {
        return '$hours hr ${mins > 0 ? '$mins min' : ''}';
      } else {
        return '$hours sa ${mins > 0 ? '$mins dk' : ''}';
      }
    } else if (diff.inMinutes == 0) {
      return '$secs ${isEN ? 'sec' : 'sn'}';
    } else {
      return '${diff.inMinutes} ${isEN ? 'min' : 'dk'}';
    }
  }

  /// İki istasyon arası seyahat süresini dakikalar cinsinden bulur
  static int getJourneyDuration(List<String> fromTimes, List<String> toTimes) {
    if (fromTimes.isEmpty || toTimes.isEmpty) return 0;
    final fromParts = fromTimes.first.split(':');
    final toParts = toTimes.first.split(':');
    final fromTime = DateTime(2024, 1, 1, int.parse(fromParts[0]), int.parse(fromParts[1]));
    final toTime = DateTime(2024, 1, 1, int.parse(toParts[0]), int.parse(toParts[1]));
    return toTime.difference(fromTime).inMinutes.abs();
  }
}
