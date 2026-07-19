import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_web/tflite_web.dart';

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
  final String inputType;
  final List<int> outputShape;
  final String outputType;
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

  TFLiteModel? _model;
  List<String> labels = [];

  bool get isInitialized => _model != null && labels.isNotEmpty;

  TFLiteModel get model {
    final model = _model;
    if (model == null) {
      throw StateError(
        'MLService is not initialized. Call initialize() first.',
      );
    }
    return model;
  }

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    await TFLiteWeb.initializeUsingCDN();
    final modelData = await rootBundle.load(modelAssetPath);
    _model = await TFLiteModel.fromMemory(
      modelData.buffer.asUint8List(
        modelData.offsetInBytes,
        modelData.lengthInBytes,
      ),
    );
    labels = await _loadLabels();

    _validateModelLabels();
    _logModelDetails();
  }

  Future<ModelSmokeTestResult> runSmokeTest() async {
    if (!isInitialized) {
      await initialize();
    }

    final inputInfo = model.inputs.first;
    final outputInfo = model.outputs.first;
    final inputShape = _usableShape(
      inputInfo.shape,
      fallbackSize: inputImageSize,
    );
    final inputTensor = Tensor(
      _zeroFlatInput(inputShape, inputInfo.dataType),
      shape: inputShape,
      type: _tensorType(inputInfo.dataType),
    );

    final output = model.predict<Object>(inputTensor);
    final scores = await _outputScores(output);
    inputTensor.dispose();
    _disposeOutput(output);

    if (scores.isEmpty) {
      throw StateError('Model returned an empty output tensor.');
    }

    final topIndex = _topIndex(scores);
    final result = ModelSmokeTestResult(
      inputShape: inputShape,
      inputType: inputInfo.dtype,
      outputShape: _usableShape(outputInfo.shape, fallbackSize: labels.length),
      outputType: outputInfo.dtype,
      labelsCount: labels.length,
      topLabel: topIndex < labels.length ? labels[topIndex] : 'index_$topIndex',
      topScore: scores[topIndex],
    );

    _log('TFLite Web smoke test passed: $result');

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

    final inputInfo = model.inputs.first;
    final inputShape = _usableShape(
      inputInfo.shape,
      fallbackSize: inputImageSize,
    );
    final inputTensor = Tensor(
      _imageToFlatInput(resizedImage, inputInfo.dataType),
      shape: inputShape,
      type: _tensorType(inputInfo.dataType),
    );

    final output = model.predict<Object>(inputTensor);
    final scores = await _outputScores(output);
    inputTensor.dispose();
    _disposeOutput(output);

    return _topPredictions(scores, model.outputs.first.dtype, topK);
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
    final outputShape = _usableShape(
      model.outputs.first.shape,
      fallbackSize: labels.length,
    );
    final outputElements = outputShape.fold<int>(
      1,
      (total, value) => total * value,
    );

    if (outputElements != labels.length) {
      throw StateError(
        'Label count (${labels.length}) does not match model output '
        'classes ($outputElements).',
      );
    }
  }

  void _logModelDetails() {
    final inputInfo = model.inputs.first;
    final outputInfo = model.outputs.first;

    _log('Loaded TFLite Web model: $modelAssetPath');
    _log('Input: shape=${inputInfo.shape}, type=${inputInfo.dtype}');
    _log('Output: shape=${outputInfo.shape}, type=${outputInfo.dtype}');
    _log('Labels loaded: ${labels.length}');
  }

  List<int> _usableShape(List<int>? shape, {required int fallbackSize}) {
    if (shape == null || shape.isEmpty) {
      return [1, fallbackSize];
    }

    return [for (final value in shape) value <= 0 ? 1 : value];
  }

  Object _zeroFlatInput(List<int> shape, TFLiteDataType dataType) {
    final elementCount = shape.fold<int>(1, (total, value) => total * value);
    if (dataType == TFLiteDataType.float32) {
      return Float32List(elementCount);
    }
    return Int32List(elementCount);
  }

  Object _imageToFlatInput(img.Image image, TFLiteDataType dataType) {
    final elementCount = inputImageSize * inputImageSize * 3;

    if (dataType == TFLiteDataType.float32) {
      final input = Float32List(elementCount);
      var offset = 0;
      for (var y = 0; y < inputImageSize; y++) {
        for (var x = 0; x < inputImageSize; x++) {
          final pixel = image.getPixel(x, y);
          input[offset++] = pixel.r / 255.0;
          input[offset++] = pixel.g / 255.0;
          input[offset++] = pixel.b / 255.0;
        }
      }
      return input;
    }

    final input = Int32List(elementCount);
    var offset = 0;
    for (var y = 0; y < inputImageSize; y++) {
      for (var x = 0; x < inputImageSize; x++) {
        final pixel = image.getPixel(x, y);
        input[offset++] = pixel.r.round() - 128;
        input[offset++] = pixel.g.round() - 128;
        input[offset++] = pixel.b.round() - 128;
      }
    }
    return input;
  }

  TFLiteDataType _tensorType(TFLiteDataType dataType) {
    return dataType == TFLiteDataType.float32
        ? TFLiteDataType.float32
        : TFLiteDataType.int32;
  }

  Future<List<num>> _outputScores(Object output) async {
    try {
      return _numbersFromTensor(output as Tensor);
    } catch (_) {
      // Not a Tensor, try NamedTensorMap
    }

    try {
      final namedMap = output as NamedTensorMap;
      final outputName = model.outputs.first.name;
      return _numbersFromTensor(namedMap[outputName]);
    } catch (_) {
      // Not a NamedTensorMap, flatten the values
    }

    return _flattenNumbers(output);
  }

  List<num> _numbersFromTensor(Tensor tensor) {
    final values = tensor.dataSync<List<num>>();
    return values.toList(growable: false);
  }

  void _disposeOutput(Object output) {
    try {
      (output as Tensor).dispose();
    } catch (_) {
      // Not a Tensor, try NamedTensorMap
    }

    try {
      final namedMap = output as NamedTensorMap;
      namedMap[model.outputs.first.name].dispose();
    } catch (_) {
      // Not a NamedTensorMap, nothing to dispose
    }
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
    String outputType,
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

  double _confidence(num score, String outputType) {
    if (outputType == 'uint8') {
      return (score / 255.0).clamp(0.0, 1.0);
    }
    if (outputType == 'int8') {
      return ((score + 128.0) / 255.0).clamp(0.0, 1.0);
    }
    if (score > 1) {
      return (score / 255.0).clamp(0.0, 1.0);
    }
    return score.toDouble().clamp(0.0, 1.0);
  }

  void _log(String message) {
    developer.log(message, name: 'MLService');
    debugPrint('MLService: $message');
  }

  void dispose() {
    _model = null;
    labels = [];
  }
}
