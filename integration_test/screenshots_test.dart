import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fullseller_app/main.dart' as app;
import 'package:fullseller_app/services/auth_repository.dart';

const _phone = String.fromEnvironment('FS_PHONE');
const _password = String.fromEnvironment('FS_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    app.main();
    for (var i = 0; i < 56; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> settle(int seconds) async {
      for (var i = 0; i < seconds * 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> shot(String name, {int seconds = 10}) async {
      await settle(seconds);
      await binding.takeScreenshot('tmp'); // первый кадр может быть устаревшим
      await settle(2);
      await binding.takeScreenshot(name);
    }

    NavigatorState nav() => tester.state<NavigatorState>(find.byType(Navigator).first);

    await shot('01_login', seconds: 3);

    await AuthRepository.login(_phone, _password);

    nav().pushNamedAndRemoveUntil('/home', (_) => false);
    await shot('02_home', seconds: 14);

    nav().pushNamed('/categories');
    await shot('03_categories');

    nav().pushNamed('/cargo-calculator');
    await shot('04_cargo');

    nav().pushNamed('/full-ai');
    await shot('05_full_ai');

    nav().pushNamed('/profile');
    await shot('06_profile');
  });
}
