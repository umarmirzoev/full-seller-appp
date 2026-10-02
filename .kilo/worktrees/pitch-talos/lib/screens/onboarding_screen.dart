import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide(this.icon, this.title, this.subtitle);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(Icons.inventory_2_outlined, 'Оптовый каталог', 'Носки, футболки, бельё и штаны — тысячи позиций по фабричным ценам.'),
    _Slide(Icons.local_shipping_outlined, 'Доставка карго', 'Считайте стоимость доставки в Россию и Таджикистан прямо в приложении.'),
    _Slide(Icons.auto_awesome_rounded, 'FULL AI-ассистент', 'Подбор товара, расчёт партии и ответы на вопросы — прямо в чате.'),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
                child: Text('Пропустить', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.text3)),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (context, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(40)),
                      child: Icon(s.icon, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 36),
                    Text(s.title, textAlign: TextAlign.center, style: AppTextStyles.display(size: 21)),
                    const SizedBox(height: 12),
                    Text(s.subtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.text2)),
                  ]),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(4)),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_page == _slides.length - 1 ? 'Начать' : 'Далее'),
            ),
          ),
        ]),
      ),
    );
  }
}
