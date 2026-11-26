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

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(preferences);
  final sharedPreferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageService(sharedPreferences),
        ),
        ChangeNotifierProvider(create: (_) => ThemeService(sharedPreferences)),
      ],
      child: const CropDiseaseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void useSize(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('home renders the redesigned dashboard', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    // Brand block.
    expect(find.text('Multi-Crop'), findsOneWidget);
    expect(find.text('Disease Detector'), findsOneWidget);

    // Hero copy, split into a dark lead and a green accent line.
    // The lead and the accent word are one rich-text run.
    expect(
      find.textContaining('Detect Plant', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Instantly', findRichText: true),
      findsOneWidget,
    );

    // The two full-width actions.
    expect(find.text('Scan with Camera'), findsOneWidget);
    expect(find.text('Upload from Gallery'), findsOneWidget);

    // Crops card.
    expect(find.text('Supported Crops'), findsOneWidget);
    expect(find.text('16+ Crops'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('More…'), findsOneWidget);

    // Four-item taskbar.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard uses vertical space above the taskbar', (
    tester,
  ) async {
    useSize(tester, const Size(360, 800));
    await pumpApp(tester);

    final leafImage = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/Leaf_Scan_UI.png',
    );
    final headline = find.textContaining('Detect Plant', findRichText: true);
    final headlineRight = tester.getRect(headline).right;
    final leafLeft = tester.getRect(leafImage).left;
    final cropsCardBottom = tester.getRect(find.text('More…')).bottom;
    final taskbarTop = tester.getRect(find.text('Home')).top;

    expect(tester.getSize(leafImage).width, greaterThan(170));
    expect(tester.getSize(leafImage).height, greaterThanOrEqualTo(200));
    expect(headlineRight - leafLeft, lessThanOrEqualTo(20));
    expect(cropsCardBottom, lessThan(taskbarTop));
    expect(taskbarTop - cropsCardBottom, lessThan(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard scrolls when content exceeds the viewport', (
    tester,
  ) async {
    useSize(tester, const Size(320, 480));
    await pumpApp(tester);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan and upload actions open the camera screen', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    await tester.tap(find.text('Scan with Camera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CameraScreen), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload from Gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CameraScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taskbar switches between all four destinations', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scan History'), findsWidgets);

    await tester.tap(find.text('Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StatisticsScreen), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scan with Camera'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('settings entry points open the disease library', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Disease Library').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);
  });

  testWidgets('crops card opens the disease browser', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    await tester.tap(find.text('More…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);
  });

  testWidgets('dashboard copy follows Bengali selection', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester, preferences: {'selected_language': 'bn'});

    expect(
      find.textContaining('গাছের রোগ', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('সহজেই', findRichText: true), findsOneWidget);
    expect(find.text('সমর্থিত ফসল'), findsOneWidget);
  });

  testWidgets('dashboard copy follows Urdu selection', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester, preferences: {'selected_language': 'ur'});

    expect(
      find.textContaining('پودوں کی بیماریاں', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('فوراً', findRichText: true), findsOneWidget);
    expect(find.text('معاون فصلیں'), findsOneWidget);
  });

  testWidgets('theme toggle updates the dashboard theme', (tester) async {
    useSize(tester, const Size(412, 915));
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('dashboard adapts to phone and tablet widths', (tester) async {
    useSize(tester, const Size(360, 800));

    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final entry in const <String, Map<String, Object>>{
    'en': {},
    'bn': {'selected_language': 'bn'},
    'ur': {'selected_language': 'ur'},
  }.entries) {
    testWidgets('no overflow on a 320dp screen (${entry.key})', (tester) async {
      useSize(tester, const Size(320, 640));
      await pumpApp(tester, preferences: entry.value);

      expect(
        tester.takeException(),
        isNull,
        reason: 'the dashboard must fit a 320dp-wide screen',
      );
    });
  }
}
