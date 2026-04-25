import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

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
            scaffoldBackgroundColor: AppColors.backgroundLight,
            primaryColor: AppColors.primaryNavy,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              primary: AppColors.primaryNavy,
              secondary: AppColors.accentYellow,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
              titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
              bodyLarge: TextStyle(color: AppColors.textDark),
              bodyMedium: TextStyle(color: AppColors.textMedium),
            ),
            cardTheme: CardTheme(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.cardWhite,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: AppColors.cardWhite,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: AppColors.lightBlue,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
