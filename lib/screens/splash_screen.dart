import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final loggedIn = await AuthRepository.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: Text('FS', style: AppTextStyles.display(size: 30, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 18),
          Text('FULL SELLER', style: AppTextStyles.display(size: 20, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Оптовый маркетплейс', style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 40),
          const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
        ]),
      ),
    );
  }
}
