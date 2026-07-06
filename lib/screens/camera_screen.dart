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
        _cameraError = 'Camera unavailable: $error';
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
      _showError('Could not capture image: $error');
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

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedImage == null) {
      return;
    }

    final imageBytes = await pickedImage.readAsBytes();
    final savedPath = await ImageStorageService().saveScanImage(imageBytes);
    await _analyzeImage(imageBytes: imageBytes, imagePath: savedPath);
  }

  Future<void> _analyzeCapturedImage() async {
    final imageBytes = _capturedImageBytes;
    if (imageBytes == null) {
      return;
    }

    await _analyzeImage(
      imageBytes: imageBytes,
      imagePath: _capturedImagePath,
    );
  }

  Future<void> _analyzeImage({
    required Uint8List imageBytes,
    required String? imagePath,
  }) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final predictions = await MLService().classifyImageBytes(imageBytes);
      final topPrediction = predictions.isEmpty ? null : predictions.first;

      if (topPrediction != null) {
        final diseaseInfo = await DiseaseInfoService().findByPredictionLabel(
          topPrediction.label,
          language: AppLanguage.english,
        );

        await DatabaseService().insertScan(
          ScanRecord(
            imagePath: imagePath ?? '',
            imageBytesBase64: _historyImageBase64(imageBytes),
            diseaseName: topPrediction.label,
            confidence: topPrediction.confidence,
            timestamp: DateTime.now(),
            cropName: diseaseInfo.crop,
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
      _showError('Could not analyze image: $error');
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
    final historyImage = longestSide > 640
        ? img.copyResize(
            orientedImage,
            width: orientedImage.width >= orientedImage.height ? 640 : null,
            height: orientedImage.height > orientedImage.width ? 640 : null,
            interpolation: img.Interpolation.linear,
          )
        : orientedImage;

    return base64Encode(img.encodeJpg(historyImage, quality: 82));
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
    final selectedLanguage = context.watch<LanguageService>().language;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Leaf'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(selectedLanguage.label)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Live Camera Preview', style: theme.textTheme.titleMedium),
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
              label: Text(_isCapturing ? 'Saving Image' : 'Capture Image'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _retakeImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
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
                    label: Text(_isProcessing ? 'Analyzing' : 'Analyze Image'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isProcessing ? null : _selectGalleryImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Select Image from Gallery'),
          ),
          const SizedBox(height: 24),
          Text('Camera Integration', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _PipelineStep(
            icon: Icons.camera_alt_outlined,
            title: 'Open Camera',
          ),
          const _PipelineStep(
            icon: Icons.preview_outlined,
            title: 'Show Live Preview',
          ),
          const _PipelineStep(
            icon: Icons.radio_button_checked,
            title: 'Capture Image',
          ),
          const _PipelineStep(icon: Icons.save_alt, title: 'Save Image'),
          const _PipelineStep(
            icon: Icons.image_outlined,
            title: 'Preview Image',
            isLast: true,
          ),
          const SizedBox(height: 24),
          Text('After Camera Works', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _PipelineStep(icon: Icons.image, title: 'Captured Image'),
          const _PipelineStep(icon: Icons.crop_free, title: 'Resize 224×224'),
          const _PipelineStep(
            icon: Icons.data_object,
            title: 'Tensor Conversion',
          ),
          const _PipelineStep(icon: Icons.memory, title: 'TFLite Inference'),
          const _PipelineStep(
            icon: Icons.workspace_premium_outlined,
            title: 'Top-3 Predictions',
          ),
          const _PipelineStep(
            icon: Icons.medical_information_outlined,
            title: 'Disease Information Screen',
            isLast: true,
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
                const _CameraMessage(message: 'Open Camera'),
              if (capturedImageBytes == null && error == null)
                const _LeafGuideOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafGuideOverlay extends StatelessWidget {
  const _LeafGuideOverlay();

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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Put Leaf Here',
                    style: TextStyle(
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

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.icon,
    required this.title,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(icon, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
      ],
    );
  }
}
