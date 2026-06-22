import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/main.dart';
import 'package:multi_crop_disease_detector/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LanguageService(preferences),
      child: const CropDiseaseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home screen displays dashboard content', (tester) async {
    await pumpApp(tester);

    expect(find.text('Multi Crop Disease Detector'), findsOneWidget);
    expect(find.text('AI Plant Disease Detection'), findsOneWidget);
    expect(
      find.text('Detect diseases across multiple crops using TensorFlow Lite.'),
      findsOneWidget,
    );
    expect(find.text('Start Scan'), findsOneWidget);
  });

  testWidgets('Start Scan opens camera capture pipeline', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Start Scan'));
    await tester.pump();

    expect(find.text('Live Camera Preview'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Disease Information Screen'),
      500,
    );

    expect(find.text('Tensor Conversion'), findsOneWidget);
    expect(find.text('TFLite Inference'), findsOneWidget);
    expect(find.text('Top-3 Predictions'), findsOneWidget);
    expect(find.text('Disease Information Screen'), findsOneWidget);
  });
}
