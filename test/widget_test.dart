import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/main.dart';
import 'package:multi_crop_disease_detector/screens/browse_diseases_screen.dart';
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

void main() {
  testWidgets('home displays the redesigned dashboard and floating taskbar', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Multi Crop Disease Detector'), findsOneWidget);
    expect(find.text('Detect Plant\nDiseases Early'), findsOneWidget);
    expect(find.text('Start Detection'), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Supported Crops'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Supported Crops'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('hero and quick actions open their existing destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Start Detection'));
    await tester.pump();
    expect(find.text('Scan Leaf'), findsOneWidget);
    expect(find.text('Live Camera Preview'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan History'));
    await tester.pump();
    expect(find.text('Scan History'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Disease Information'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Disease Information'));
    await tester.pump();
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);
  });

  testWidgets('crop view-all and taskbar navigate to the disease browser', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('View all'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View all'));
    await tester.pump();
    expect(find.byType(BrowseDiseasesScreen), findsOneWidget);

    await tester.tap(find.text('Statistics'));
    await tester.pump();
    expect(find.byType(StatisticsScreen), findsOneWidget);
  });

  testWidgets('dashboard copy follows Bengali selection', (tester) async {
    await pumpApp(tester, preferences: {'selected_language': 'bn'});
    expect(find.textContaining('গাছের রোগ'), findsOneWidget);
    expect(find.text('সমর্থিত ফসল'), findsOneWidget);
  });

  testWidgets('dashboard copy follows Urdu selection', (tester) async {
    await pumpApp(tester, preferences: {'selected_language': 'ur'});
    expect(find.textContaining('پودوں کی بیماریاں'), findsOneWidget);
    expect(find.text('معاون فصلیں'), findsOneWidget);
  });

  testWidgets('theme toggle updates the dashboard theme', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('dashboard adapts to phone and tablet widths', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;

    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
