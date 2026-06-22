import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';

class ModelSmokeTestResult {
  const ModelSmokeTestResult({
    required this.inputShape,
    required this.inputType,
    required this.outputShape,
    required this.outputType,
    required this.labelsCount,
    required this.topLabel,
    required this.topScore,
  });

  final List<int> inputShape;
  final TensorType inputType;
  final List<int> outputShape;
  final TensorType outputType;
  final int labelsCount;
  final String topLabel;
  final num topScore;

  @override
  String toString() {
    return 'input=$inputShape/$inputType, '
        'output=$outputShape/$outputType, '
        'labels=$labelsCount, '
        'top=$topLabel ($topScore)';
  }
}

class MLService {
  MLService._internal();

  factory MLService() => _instance;

  static final MLService _instance = MLService._internal();

  static const String modelAssetPath = 'assets/models/mobilenetv2_int8.tflite';
  static const String labelsAssetPath = 'assets/labels/labels.txt';
  static const int inputImageSize = 224;

  Interpreter? _interpreter;
  List<String> labels = [];

  bool get isInitialized => _interpreter != null && labels.isNotEmpty;

  Interpreter get interpreter {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(
        'MLService is not initialized. Call initialize() first.',
      );
    }
    return interpreter;
  }

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    _interpreter = await Interpreter.fromAsset(modelAssetPath);
    labels = await _loadLabels();

    _validateModelLabels();
    _logModelDetails();
  }

  Future<ModelSmokeTestResult> runSmokeTest() async {
    if (!isInitialized) {
      await initialize();
    }

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final input = _zeroTensor(inputTensor.shape, inputTensor.type);
    final output = _zeroTensor(outputTensor.shape, outputTensor.type);

    interpreter.run(input, output);

    final scores = _flattenNumbers(output);
    if (scores.isEmpty) {
      throw StateError('Model returned an empty output tensor.');
    }

    final topIndex = _topIndex(scores);
    final result = ModelSmokeTestResult(
      inputShape: inputTensor.shape,
      inputType: inputTensor.type,
      outputShape: outputTensor.shape,
      outputType: outputTensor.type,
      labelsCount: labels.length,
      topLabel: topIndex < labels.length ? labels[topIndex] : 'index_$topIndex',
      topScore: scores[topIndex],
    );

    _log('TFLite smoke test passed: $result');

    return result;
  }

  Future<List<Prediction>> classifyImageBytes(
    Uint8List imageBytes, {
    int topK = 3,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw ArgumentError('Selected file is not a supported image.');
    }

    final orientedImage = img.bakeOrientation(decodedImage);
    final resizedImage = img.copyResize(
      orientedImage,
      width: inputImageSize,
      height: inputImageSize,
      interpolation: img.Interpolation.linear,
    );

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final input = _imageToInputTensor(resizedImage, inputTensor.type);
    final output = _zeroTensor(outputTensor.shape, outputTensor.type);

    interpreter.run(input, output);

    final scores = _flattenNumbers(output);
    return _topPredictions(scores, outputTensor.type, topK);
  }

  Future<List<String>> _loadLabels() async {
    final labelData = await rootBundle.loadString(labelsAssetPath);
    return labelData
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

  void _validateModelLabels() {
    final outputElements = interpreter.getOutputTensor(0).numElements();
    if (labels.length != outputElements) {
      throw StateError(
        'Label count (${labels.length}) does not match model output '
        'classes ($outputElements).',
      );
    }
  }

  void _logModelDetails() {
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);

    _log('Loaded TFLite model: $modelAssetPath');
    _log('Input: shape=${inputTensor.shape}, type=${inputTensor.type}');
    _log('Output: shape=${outputTensor.shape}, type=${outputTensor.type}');
    _log('Labels loaded: ${labels.length}');
  }

  Object _zeroTensor(List<int> shape, TensorType type) {
    final elementCount = shape.fold<int>(1, (total, value) => total * value);
    final flat = switch (type) {
      TensorType.float32 ||
      TensorType.float64 ||
      TensorType.float16 => List<num>.filled(elementCount, 0.0),
      _ => List<num>.filled(elementCount, 0),
    };

    return _reshape(flat, shape);
  }

  Object _imageToInputTensor(img.Image image, TensorType type) {
    return [
      List.generate(inputImageSize, (y) {
        return List.generate(inputImageSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            _preprocessChannel(pixel.r, type),
            _preprocessChannel(pixel.g, type),
            _preprocessChannel(pixel.b, type),
          ];
        });
      }),
    ];
  }

  num _preprocessChannel(num value, TensorType type) {
    final channel = value.clamp(0, 255);
    return switch (type) {
      TensorType.float32 ||
      TensorType.float64 ||
      TensorType.float16 => channel / 255.0,
      TensorType.int8 => channel.round() - 128,
      _ => channel.round(),
    };
  }

  Object _reshape(List<num> flat, List<int> shape) {
    Object build(int depth, int offset) {
      if (depth == shape.length - 1) {
        return flat.sublist(offset, offset + shape[depth]);
      }

      final stride = shape
          .sublist(depth + 1)
          .fold<int>(1, (total, value) => total * value);

      return List<Object>.generate(
        shape[depth],
        (index) => build(depth + 1, offset + index * stride),
      );
    }

    return shape.isEmpty ? flat.first : build(0, 0);
  }

  List<num> _flattenNumbers(Object value) {
    final values = <num>[];

    void visit(Object? item) {
      if (item is num) {
        values.add(item);
      } else if (item is Iterable) {
        for (final child in item) {
          visit(child);
        }
      }
    }

    visit(value);
    return values;
  }

  int _topIndex(List<num> values) {
    var bestIndex = 0;
    var bestValue = -double.infinity;

    for (var index = 0; index < values.length; index++) {
      final value = values[index].toDouble();
      if (value > bestValue || value == bestValue && index < bestIndex) {
        bestIndex = index;
        bestValue = value;
      }
    }

    return math.min(bestIndex, values.length - 1);
  }

  List<Prediction> _topPredictions(
    List<num> scores,
    TensorType outputType,
    int topK,
  ) {
    final indexedScores = <({int index, num score})>[
      for (var index = 0; index < scores.length; index++)
        (index: index, score: scores[index]),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return indexedScores
        .take(topK)
        .map((entry) {
          return Prediction(
            label: entry.index < labels.length
                ? labels[entry.index]
                : 'Unknown',
            confidence: _confidence(entry.score, outputType),
          );
        })
        .toList(growable: false);
  }

  double _confidence(num score, TensorType outputType) {
    return switch (outputType) {
      TensorType.uint8 => (score / 255.0).clamp(0.0, 1.0),
      TensorType.int8 => ((score + 128.0) / 255.0).clamp(0.0, 1.0),
      _ => score.toDouble().clamp(0.0, 1.0),
    };
  }

  void _log(String message) {
    developer.log(message, name: 'MLService');
    debugPrint('MLService: $message');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    labels = [];
  }
}
