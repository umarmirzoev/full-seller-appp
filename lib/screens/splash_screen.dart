import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

/// Анимированная заставка FULL SELLER:
/// переливающийся оранжевый фон, частицы, вращающееся кольцо иконок товаров,
/// пульсирующий логотип и плавный уход на следующий экран.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _Particle {
  double x, y, r, speed, drift, alpha;
  _Particle(Random rnd)
      : x = rnd.nextDouble(),
        y = rnd.nextDouble(),
        r = 1.2 + rnd.nextDouble() * 2.8,
        speed = 0.02 + rnd.nextDouble() * 0.05,
        drift = (rnd.nextDouble() - 0.5) * 0.02,
        alpha = 0.15 + rnd.nextDouble() * 0.35;

  void update(double dt) {
    y -= speed * dt;
    x += drift * dt;
    if (y < -0.05) {
      y = 1.05;
    }
    if (x < -0.05) x = 1.05;
    if (x > 1.05) x = -0.05;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double tick;
  _ParticlePainter(this.particles, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      paint.color = Colors.white.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _minSplash = Duration(milliseconds: 3800);

  static const _icons = <IconData>[
    Icons.checkroom_rounded, // футболки
    Icons.local_shipping_rounded, // карго
    Icons.inventory_2_rounded, // склад / партии
    Icons.shopping_bag_rounded,
    Icons.sell_rounded,
    Icons.storefront_rounded,
    Icons.payments_rounded,
    Icons.auto_awesome_rounded, // FULL AI
    Icons.straighten_rounded, // размеры
    Icons.local_offer_rounded,
  ];

  late final AnimationController _intro; // появление логотипа
  late final AnimationController _iconsIn; // появление иконок по очереди
  late final AnimationController _orbit; // вращение кольца
  late final AnimationController _pulse; // пульс логотипа
  late final AnimationController _bg; // перелив фона
  late final AnimationController _ticker; // частицы
  late final AnimationController _dots; // точки загрузки
  late final AnimationController _exit; // уход

  final _rnd = Random(7);
  late final List<_Particle> _particles = List.generate(34, (_) => _Particle(_rnd));
  double _lastTick = 0;
  bool _navigated = false;
  Timer? _safety;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _iconsIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_tickParticles);
    _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
    _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _iconsIn.forward();
    });
    // Страховка: даже если что-то зависло, через 7 секунд уходим дальше.
    _safety = Timer(const Duration(seconds: 7), () => _go(false));
    _bootstrap();
  }

  void _tickParticles() {
    final now = _ticker.value;
    var dt = now - _lastTick;
    if (dt < 0) dt += 1;
    _lastTick = now;
    for (final p in _particles) {
      p.update(dt * 2);
    }
  }

  Future<void> _bootstrap() async {
    var loggedIn = false;
    final started = DateTime.now();
    try {
      loggedIn = await AuthRepository.isLoggedIn().timeout(const Duration(seconds: 3));
    } catch (_) {}
    final left = _minSplash - DateTime.now().difference(started);
    if (left > Duration.zero) await Future.delayed(left);
    await _go(loggedIn);
  }

  Future<void> _go(bool loggedIn) async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _safety?.cancel();
    await _exit.forward();
    if (!mounted) return;
    final Widget next = loggedIn ? const HomeScreen() : const AuthScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      settings: RouteSettings(name: loggedIn ? AppRoutes.home : AppRoutes.auth),
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, __, ___) => next,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(curved), child: child),
        );
      },
    ));
  }

  @override
  void dispose() {
    _safety?.cancel();
    _ticker.removeListener(_tickParticles);
    for (final c in [_intro, _iconsIn, _orbit, _pulse, _bg, _ticker, _dots, _exit]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g600,
      body: AnimatedBuilder(
        animation: _exit,
        builder: (context, child) => Opacity(opacity: 1 - _exit.value, child: child),
        child: Stack(fit: StackFit.expand, children: [
          // ── Переливающийся фон ──
          AnimatedBuilder(
            animation: _bg,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_bg.value);
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.4 + t * 0.8, -0.6 + t * 1.0),
                    radius: 1.35 + t * 0.35,
                    colors: const [Color(0xFFFFB15C), AppColors.g500, Color(0xFFE63E00)],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // ── Частицы ──
          AnimatedBuilder(
            animation: _ticker,
            builder: (context, _) => CustomPaint(painter: _ParticlePainter(_particles, _ticker.value)),
          ),

          // ── Кольцо иконок товаров ──
          LayoutBuilder(builder: (context, box) {
            final radius = min(box.maxWidth, box.maxHeight) * 0.36;
            return AnimatedBuilder(
              animation: Listenable.merge([_orbit, _iconsIn, _pulse]),
              builder: (context, _) {
                final rot = _orbit.value * 2 * pi;
                final n = _icons.length;
                return Stack(
                  children: List.generate(n, (i) {
                    final start = i / n * 0.6;
                    final appear = Curves.easeOut.transform(
                      ((_iconsIn.value - start) / 0.4).clamp(0.0, 1.0),
                    );
                    if (appear <= 0) return const SizedBox.shrink();
                    final angle = rot + i * 2 * pi / n - pi / 2;
                    final bob = sin(_pulse.value * pi + i) * 4;
                    final r = radius * (0.65 + 0.35 * appear) + (i.isEven ? 0 : radius * 0.12);
                    final dx = cos(angle) * r;
                    final dy = sin(angle) * r * 1.18 + bob;
                    final size = 50.0 + (i % 3) * 6;
                    return Positioned(
                      left: box.maxWidth / 2 + dx - size / 2,
                      top: box.maxHeight / 2 + dy - size / 2,
                      child: Opacity(
                        opacity: appear,
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * Curves.easeOutBack.transform(appear),
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                              boxShadow: [
                                BoxShadow(color: AppColors.g900.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: Icon(_icons[i], color: Colors.white, size: size * 0.46),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            );
          }),

          // ── Логотип в центре ──
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _exit]),
              builder: (context, child) {
                final v = Curves.easeOutBack.transform(_intro.value);
                return Opacity(
                  opacity: _intro.value.clamp(0.0, 1.0),
                  child: Transform.scale(scale: (0.85 + 0.15 * v) * (1 + _exit.value * 0.12), child: child),
                );
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final p = _pulse.value;
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25 + p * 0.2),
                            blurRadius: 30 + p * 30,
                            spreadRadius: 4 + p * 10,
                          ),
                          BoxShadow(color: AppColors.g900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Transform.rotate(angle: sin(p * pi) * 0.08, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/logo/fs_logo.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'FULL SELLER',
                  style: AppTextStyles.display(size: 28, weight: FontWeight.w800, color: Colors.white).copyWith(
                    letterSpacing: 1,
                    shadows: [Shadow(color: AppColors.g900.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 4))],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text('Оптовый маркетплейс · цены фабрики',
                      style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 28),
                _LoadingDots(controller: _dots),
              ]),
            ),
          ),

          // ── Нижняя подпись ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _intro, curve: const Interval(0.4, 1)),
                child: Text(
                  'Носки • Футболки • Бельё • Доставка карго',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.75))
                      .copyWith(letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (controller.value - i * 0.18) % 1.0;
          final lift = sin(t * pi).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 9,
            height: 9,
            transform: Matrix4.translationValues(0, -8 * lift, 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5 + 0.5 * lift),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
