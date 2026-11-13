import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/main.dart';
import 'package:multi_crop_disease_detector/services/language_service.dart';
import 'package:multi_crop_disease_detector/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _boot(WidgetTester tester, Size size) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;

  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService(preferences)),
        ChangeNotifierProvider(create: (_) => ThemeService(preferences)),
      ],
      child: const CropDiseaseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return preferences;
}

void main() {
  for (final size in const [
    Size(360, 800), // typical Android phone
    Size(412, 915), // large Android phone
    Size(800, 600), // test default
  ]) {
    testWidgets('language menu opens at ${size.width.toInt()}dp', (tester) async {
      await _boot(tester, size);

      expect(tester.takeException(), isNull, reason: 'layout error before tap');

      final globe = find.byIcon(Icons.language_rounded);
      expect(globe, findsOneWidget, reason: 'globe missing at this width');

      await tester.tap(globe);
      await tester.pumpAndSettle();

      expect(
        find.text('বাংলা'),
        findsOneWidget,
        reason: 'menu did not open at ${size.width.toInt()}dp',
      );
    });
  }

  testWidgets('selecting a language applies it at phone width', (
    tester,
  ) async {
    final preferences = await _boot(tester, const Size(360, 800));

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    expect(preferences.getString('selected_language'), 'bn');
    expect(find.textContaining('গাছের রোগ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('language menu still opens after a theme toggle', (
    tester,
  ) async {
    await _boot(tester, const Size(360, 800));

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    final globe = find.byIcon(Icons.language_rounded);
    expect(globe, findsOneWidget);

    await tester.tap(globe);
    await tester.pumpAndSettle();
    expect(find.text('বাংলা'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
