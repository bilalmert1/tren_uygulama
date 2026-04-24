import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();
  static SharedPreferences? _prefs;

  Locale _locale = const Locale('tr', 'TR');
  List<String> _favoriteStationNames = [];
  List<String> _reportedIssues = [];

  Locale get locale => _locale;
  List<String> get favoriteStationNames =>
      List.unmodifiable(_favoriteStationNames);
  List<String> get reportedIssues => List.unmodifiable(_reportedIssues);

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    instance._loadData();
  }

  void _loadData() {
    final lang = _prefs?.getString('language') ?? 'tr';
    _locale =
        lang == 'en' ? const Locale('en', 'US') : const Locale('tr', 'TR');
    _favoriteStationNames = _prefs?.getStringList('favorites') ?? [];
    _reportedIssues = _prefs?.getStringList('issues') ?? [];
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _prefs?.setString('language', locale.languageCode);
    notifyListeners();
  }

  bool isFavorite(String stationName) =>
      _favoriteStationNames.contains(stationName);

  void toggleFavorite(String stationName) {
    if (_favoriteStationNames.contains(stationName)) {
      _favoriteStationNames.remove(stationName);
    } else {
      _favoriteStationNames.add(stationName);
    }
    _prefs?.setStringList('favorites', List.from(_favoriteStationNames));
    notifyListeners();
  }

  void addIssue(String issue) {
    final now = DateTime.now();
    final formatted =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}: $issue';
    _reportedIssues.insert(0, formatted);
    _prefs?.setStringList('issues', List.from(_reportedIssues));
    notifyListeners();
  }

  /// Basit çeviri yardımcısı
  String tr(String trText, String enText) {
    return _locale.languageCode == 'en' ? enText : trText;
  }
}
