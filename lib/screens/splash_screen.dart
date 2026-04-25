import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _trainMoveAnimation;
  late Animation<Offset> _textMoveAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Yazılar soldan gelmeye devam etsin (Daha erken)
    _textMoveAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    // TREN DÜZELTMESİ: Sağdan sola doğru geliyor (Daha geç)
    _trainMoveAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: const Offset(0.2, 0.0), // Önü ekranda, arkası sağ dışarıda kalır
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();

    Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScaffold(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Rayların dikey konumu (Arka planla eşleşmesi için)
    final verticalBase = size.height * 0.5; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. SABİT ARKA PLAN (Tam merkezde)
          Center(
            child: Image.asset(
              'assets/images/drawer_header_bg.png',
              fit: BoxFit.fitWidth,
              width: size.width,
            ),
          ),
          
          // 2. HAREKETLİ YAZILAR (Soldan gelir)
          SlideTransition(
            position: _textMoveAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  Positioned(
                    top: verticalBase - 160,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: Text(
                        'ANKARA BANLİYÖ',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryNavy,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: verticalBase + 180,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'BAŞKENTRAY TAKİP SİSTEMİ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(height: 3, width: 60, color: AppColors.accentYellow),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. HAREKETLİ TREN (Sağdan sola - Burnu önde)
          SlideTransition(
            position: _trainMoveAnimation,
            child: Stack(
              children: [
                Positioned(
                  top: verticalBase - (size.width * 0.5), // Milimetrik hizalama ayarı
                  left: 0,
                  child: SizedBox(
                    width: size.width * 1.5,
                    child: Transform.flip(
                      flipX: true, // Treni sola bakacak şekilde çeviriyoruz
                      child: Image.asset(
                        'assets/images/train_solo.png',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Alt yükleme çubuğu
          Positioned(
            bottom: 60,
            left: size.width * 0.4,
            right: size.width * 0.4,
            child: const LinearProgressIndicator(
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 1,
            ),
          ),
        ],
      ),
    );
  }
}
