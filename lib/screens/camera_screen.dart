import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../services/database_service.dart';
import '../services/disease_info_service.dart';
import '../services/app_localizations.dart';
import '../services/image_storage_service.dart';
import '../services/language_service.dart';
import '../services/ml_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  bool _isInitializingCamera = true;
  bool _isCapturing = false;
  bool _isProcessing = false;
  Uint8List? _capturedImageBytes;
  String? _capturedImagePath;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found on this device.');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController?.dispose();
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializingCamera = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraController = null;
        _isInitializingCamera = false;
        _cameraError = AppLocalizations.read(
          context,
        ).text('camera_unavailable', values: {'error': '$error'});
      });
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (_isCapturing ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final captured = await controller.takePicture();
      final imageBytes = await captured.readAsBytes();
      final savedPath = await ImageStorageService().saveScanImage(imageBytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedImageBytes = imageBytes;
        _capturedImagePath = savedPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        AppLocalizations.read(
          context,
        ).text('capture_failed', values: {'error': '$error'}),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _selectGalleryImage() async {
    if (_isProcessing) {
      return;
    }

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedImage == null) {
        return;
      }

      final imageBytes = await pickedImage.readAsBytes();
      final savedPath = await ImageStorageService().saveScanImage(imageBytes);
      await _analyzeImage(imageBytes: imageBytes, imagePath: savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        AppLocalizations.read(
          context,
        ).text('analysis_failed', values: {'error': '$error'}),
      );
    }
  }

  Future<void> _analyzeCapturedImage() async {
    final imageBytes = _capturedImageBytes;
    if (imageBytes == null) {
      return;
    }

    await _analyzeImage(imageBytes: imageBytes, imagePath: _capturedImagePath);
  }

  Future<void> _analyzeImage({
    required Uint8List imageBytes,
    required String? imagePath,
  }) async {
    if (_isProcessing) {
      return;
    }
    final language = context.read<LanguageService>().language;

    setState(() {
      _isProcessing = true;
    });

    try {
      final predictions = await MLService().classifyImageBytes(imageBytes);
      final topPrediction = predictions.isEmpty ? null : predictions.first;

      if (topPrediction != null) {
        final diseaseInfo = await DiseaseInfoService().findByPredictionLabel(
          topPrediction.label,
          language: language,
        );

        await DatabaseService().insertScan(
          ScanRecord(
            imagePath: imagePath ?? '',
            imageBytesBase64: _historyImageBase64(imageBytes),
            diseaseName: topPrediction.label,
            diseaseId: diseaseInfo.id,
            confidence: topPrediction.confidence,
            timestamp: DateTime.now(),
            cropName: _cropFromPredictionLabel(topPrediction.label),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: imageBytes,
            imagePath: imagePath,
            predictions: predictions,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        AppLocalizations.read(
          context,
        ).text('analysis_failed', values: {'error': '$error'}),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _retakeImage() {
    setState(() {
      _capturedImageBytes = null;
      _capturedImagePath = null;
    });
  }

  String _historyImageBase64(Uint8List imageBytes) {
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      return base64Encode(imageBytes);
    }

    final orientedImage = img.bakeOrientation(decodedImage);
    final longestSide = math.max(orientedImage.width, orientedImage.height);
    final historyImage = longestSide > 360
        ? img.copyResize(
            orientedImage,
            width: orientedImage.width >= orientedImage.height ? 360 : null,
            height: orientedImage.height > orientedImage.width ? 360 : null,
            interpolation: img.Interpolation.linear,
          )
        : orientedImage;

    return base64Encode(img.encodeJpg(historyImage, quality: 70));
  }

  String _cropFromPredictionLabel(String label) {
    return label.split('___').first.replaceAll('_', ' ').trim();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('scan_leaf')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.text('live_preview'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CameraStage(
            controller: _cameraController,
            capturedImageBytes: _capturedImageBytes,
            isInitializing: _isInitializingCamera,
            error: _cameraError,
          ),
          const SizedBox(height: 12),
          if (_capturedImageBytes == null)
            FilledButton.icon(
              onPressed: _isCapturing ? null : _captureImage,
              icon: _isCapturing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isCapturing
                    ? strings.text('saving_image')
                    : strings.text('capture_image'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _retakeImage,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.text('retake')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _analyzeCapturedImage,
                    icon: _isProcessing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics_outlined),
                    label: Text(
                      _isProcessing
                          ? strings.text('analyzing')
                          : strings.text('analyze_image'),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isProcessing ? null : _selectGalleryImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(strings.text('select_gallery')),
          ),
        ],
      ),
    );
  }
}

class _CameraStage extends StatelessWidget {
  const _CameraStage({
    required this.controller,
    required this.capturedImageBytes,
    required this.isInitializing,
    required this.error,
  });

  final CameraController? controller;
  final Uint8List? capturedImageBytes;
  final bool isInitializing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final capturedImageBytes = this.capturedImageBytes;
    final controller = this.controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (capturedImageBytes != null)
                Image.memory(capturedImageBytes, fit: BoxFit.cover)
              else if (controller != null && controller.value.isInitialized)
                CameraPreview(controller)
              else if (isInitializing)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                _CameraMessage(message: error!)
              else
                _CameraMessage(
                  message: AppLocalizations.of(context).text('scan_leaf'),
                ),
              if (capturedImageBytes == null && error == null)
                _LeafGuideOverlay(
                  message: AppLocalizations.of(context).text('put_leaf_here'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafGuideOverlay extends StatelessWidget {
  const _LeafGuideOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
