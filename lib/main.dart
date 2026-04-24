import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_state.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.initialize();

  // Durum çubuğunu şeffaf yapalım
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AnkaraTrenApp());
}

class AnkaraTrenApp extends StatelessWidget {
  const AnkaraTrenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Ankara Banliyö Takip',
          debugShowCheckedModeBanner: false,
          locale: AppState.instance.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF1A1A1A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2C3E50),
              primary: const Color(0xFF1A1A1A),
              secondary: const Color(0xFF00FF88),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontWeight: FontWeight.w900),
              headlineMedium: TextStyle(fontWeight: FontWeight.w800),
              titleLarge: TextStyle(fontWeight: FontWeight.w700),
            ),
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
            ),
          ),
          home: const MainScaffold(),
        );
      },
    );
  }
}
