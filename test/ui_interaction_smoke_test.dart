import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/main.dart';
import 'package:multi_crop_disease_detector/screens/browse_diseases_screen.dart';
import 'package:multi_crop_disease_detector/screens/camera_screen.dart';
import 'package:multi_crop_disease_detector/screens/settings_screen.dart';
import 'package:multi_crop_disease_detector/screens/statistics_screen.dart';
import 'package:multi_crop_disease_detector/services/language_service.dart';
import 'package:multi_crop_disease_detector/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app at a fixed logical size with the given language.
Future<void> _boot(
  WidgetTester tester, {
  required Size size,
  String? language,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;

  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(
    language == null ? {} : {'selected_language': language},
  );
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
}

/// Fails the test with the captured exception, if any appeared.
void _expectNoException(WidgetTester tester, String when) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: 'unexpected exception $when: $exception');
}

const _phoneSizes = [Size(320, 640), Size(360, 800), Size(412, 915)];
const _languages = [null, 'bn', 'ur'];

/// Pumps a few frames without waiting for animations to settle.
///
/// Screens backed by a database `FutureBuilder` keep a `CircularProgressIndicator`
/// spinning forever under the test harness (sqflite has no platform channel),
/// so `pumpAndSettle` would time out.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Taps a taskbar destination and lets the tab's first frame land.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _pumpFrames(tester);
}

void main() {
  group('dashboard renders without exceptions', () {
    for (final size in _phoneSizes) {
      for (final language in _languages) {
        testWidgets(
          'layout at ${size.width.toInt()}dp ${language ?? 'en'}',
          (tester) async {
            await _boot(tester, size: size, language: language);
            _expectNoException(tester, 'while building the dashboard');

            // All four destinations must be present at every width. Checked by
            // icon because the labels are localized.
            for (final icon in const [
              Icons.home_rounded,
              Icons.history_rounded,
              Icons.bar_chart_rounded,
              Icons.settings_rounded,
            ]) {
              expect(
                find.byIcon(icon),
                findsOneWidget,
                reason: 'taskbar item $icon missing at ${size.width.toInt()}dp',
              );
            }
          },
        );
      }
    }
  });

  group('dashboard controls respond to taps', () {
    for (final size in _phoneSizes) {
      testWidgets('theme toggle at ${size.width.toInt()}dp', (tester) async {
        await _boot(tester, size: size);
        final initial = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeMode;
        await tester.tap(find.byIcon(Icons.dark_mode_rounded));
        await tester.pumpAndSettle();
        final updated = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeMode;
        expect(updated, isNot(initial), reason: 'theme did not toggle');
        // Toggling back must also work (the icon flips to light_mode).
        await tester.tap(find.byIcon(Icons.light_mode_rounded));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          initial,
          reason: 'theme did not toggle back',
        );
        _expectNoException(tester, 'while toggling the theme');
      });

      for (final language in _languages) {
        testWidgets(
          'language menu opens at ${size.width.toInt()}dp '
          '${language ?? 'en'}',
          (tester) async {
            await _boot(tester, size: size, language: language);
            await tester.tap(find.byIcon(Icons.language_rounded));
            await tester.pumpAndSettle();
            _expectNoException(tester, 'while opening the language menu');
            // Every language must be offered at every width — this is the
            // regression guard for the popup that silently failed to open
            // below 400dp.
            for (final option in AppLanguage.values) {
              expect(
                find.text(option.label),
                findsOneWidget,
                reason: 'menu item ${option.label} missing',
              );
            }
          },
        );
      }
    }
  });

  testWidgets('every language can be selected at phone width', (tester) async {
    await _boot(tester, size: const Size(360, 800));
    final preferences = await SharedPreferences.getInstance();

    for (final language in AppLanguage.values) {
      await tester.tap(find.byIcon(Icons.language_rounded));
      await tester.pumpAndSettle();
      // Tap the menu item, not its Text: the label sits inside the item's
      // animated opacity layer, so a Text-targeted tap only hit-tests by
      // accident and warns.
      await tester.tap(
        find.ancestor(
          of: find.text(language.label),
          matching: find.byWidgetPredicate(
            (widget) => widget is CheckedPopupMenuItem<AppLanguage>,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // `setLanguage` returns early when the language is already active, so an
      // unset preference means English (the default) is still selected.
      expect(
        preferences.getString('selected_language') ?? 'en',
        language.code,
        reason: 'selecting ${language.label} did not persist',
      );
      _expectNoException(tester, 'after selecting ${language.label}');
    }
  });

  testWidgets('the scan pill opens the scanner', (tester) async {
    await _boot(tester, size: const Size(360, 800));

    // The camera preview keeps animating under the test harness, so settle
    // with explicit frames instead of pumpAndSettle.
    await tester.tap(find.text('Scan with Camera'));
    await _pumpFrames(tester);
    expect(find.byType(CameraScreen), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);
    _expectNoException(tester, 'after tapping Scan with Camera');
  });

  testWidgets('the gallery pill opens the scanner in picker mode', (
    tester,
  ) async {
    await _boot(tester, size: const Size(360, 800));

    await tester.ensureVisible(find.text('Upload from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Upload from Gallery'));
    await _pumpFrames(tester);

    final screen = tester.widget<CameraScreen>(find.byType(CameraScreen));
    expect(screen.openGalleryOnStart, isTrue);
    _expectNoException(tester, 'after tapping Upload from Gallery');
  });

  testWidgets('taskbar switches through all destinations at 360dp', (
    tester,
  ) async {
    await _boot(tester, size: const Size(360, 800));

    await _tapTab(tester, 'History');
    _expectNoException(tester, 'after switching to History');

    await _tapTab(tester, 'Stats');
    expect(find.byType(StatisticsScreen), findsOneWidget);
    _expectNoException(tester, 'after switching to Stats');

    await _tapTab(tester, 'Settings');
    expect(find.byType(SettingsScreen), findsOneWidget);
    _expectNoException(tester, 'after switching to Settings');

    await _tapTab(tester, 'Home');
    expect(find.text('Scan with Camera'), findsOneWidget);
    _expectNoException(tester, 'after switching back to Home');
  });

  testWidgets('settings opens the disease library at 360dp', (tester) async {
    await _boot(tester, size: const Size(360, 800));

    await _tapTab(tester, 'Settings');
    await tester.tap(find.text('Disease Library').last);
    await _pumpFrames(tester);

    // The browse screen is backed by a bundled-asset Future that never
    // resolves under the test harness, so assert it builds rather than loading
    // any rows.
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);
    _expectNoException(tester, 'while opening the library from Settings');
  });

  testWidgets('crops card "More…" opens the browser at 360dp', (tester) async {
    await _boot(tester, size: const Size(360, 800));

    await tester.scrollUntilVisible(
      find.text('More…'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('More…'));
    await _pumpFrames(tester);
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);
    _expectNoException(tester, 'after tapping More…');
  });

  testWidgets('system back returns to Home instead of exiting at 360dp', (
    tester,
  ) async {
    await _boot(tester, size: const Size(360, 800));

    // Leave the dashboard so the back button has something to undo.
    await _tapTab(tester, 'Stats');
    expect(find.byType(StatisticsScreen), findsOneWidget);

    // Simulate the Android system back gesture. `handlePopRoute` walks the
    // navigator, honouring the `PopScope` in HomeScreen.
    await tester.binding.handlePopRoute();
    await _pumpFrames(tester);

    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.text('Scan with Camera'), findsOneWidget);
    _expectNoException(tester, 'while handling the system back button');
  });
}
