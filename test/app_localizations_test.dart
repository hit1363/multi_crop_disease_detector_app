import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/services/app_localizations.dart';
import 'package:multi_crop_disease_detector/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('all languages expose the same translation keys', () {
    final english = AppLocalizations.translations['en']!.keys.toSet();

    for (final language in AppLanguage.values) {
      expect(
        AppLocalizations.translations[language.code]!.keys.toSet(),
        english,
        reason: '${language.name} is missing or has extra keys',
      );
    }
  });

  test('severity falls back to a real token for unknown values', () {
    final english = AppLocalizations(AppLanguage.english);
    final bengali = AppLocalizations(AppLanguage.bangla);
    final urdu = AppLocalizations(AppLanguage.urdu);

    expect(english.severity('moderate'), 'Moderate');
    expect(english.severity('severe'), 'Severe');

    // "N/A" used to render the raw key "severity_N/A".
    for (final strings in [english, bengali, urdu]) {
      final fallback = strings.severity('N/A');
      expect(fallback, isNot(contains('severity_')));
      expect(fallback, strings.text('severity_unknown'));
    }
    expect(english.severity('unknown'), english.text('severity_unknown'));
  });

  testWidgets('read() works outside the build phase', (tester) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({'selected_language': 'bn'});
    final preferences = await SharedPreferences.getInstance();
    final anchor = GlobalKey();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageService(preferences),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(key: anchor, builder: (_) => const SizedBox()),
          ),
        ),
      ),
    );

    // `inspect`-style calls happen from handlers, not build.
    final strings = AppLocalizations.read(anchor.currentContext!);
    expect(strings.language, AppLanguage.bangla);
    expect(strings.text('app_title'), isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}
