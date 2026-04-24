import 'package:ankara_tren/models/station.dart';

void main() {
  final ankara = Station.allStations.firstWhere((s) => s.name == 'Ankara');
  print('Ankara Sincan Yönü Saatleri:');
  final timesSincan = ankara.getTimes(TrainDirection.sincan);
  print(timesSincan);
  
  print('\nAnkara Kayaş Yönü Saatleri:');
  final timesKayas = ankara.getTimes(TrainDirection.kayas);
  print(timesKayas);
}
