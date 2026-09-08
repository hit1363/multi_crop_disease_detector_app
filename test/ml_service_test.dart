import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  test(
    'packaged TFLite model has the expected inference contract',
    () async {
      final modelFile = File('assets/models/mobilenetv2_dynamic.tflite');
      final labelsFile = File('assets/labels/labels.txt');
      final interpreter = Interpreter.fromFile(modelFile);
      addTearDown(interpreter.close);

      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final labels = await labelsFile.readAsLines().then(
        (lines) => lines.where((label) => label.trim().isNotEmpty).toList(),
      );

      final input = [
        List.generate(
          224,
          (_) => List.generate(224, (_) => List<double>.filled(3, 0.0)),
        ),
      ];
      final output = [List<double>.filled(45, 0.0)];
      interpreter.run(input, output);

      expect(inputTensor.shape, [1, 224, 224, 3]);
      expect(inputTensor.type, TensorType.float32);
      expect(outputTensor.shape, [1, 45]);
      expect(outputTensor.type, TensorType.float32);
      expect(labels, hasLength(45));
      expect(output.single, everyElement(isA<double>()));
    },
    skip: Platform.isWindows
        ? 'The Windows Flutter SDK does not bundle the TensorFlow Lite DLL.'
        : false,
  );
}
