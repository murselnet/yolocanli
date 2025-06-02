import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart'
    hide InputImageRotation;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:myapp/utils/my_text_style.dart';
import 'package:myapp/utils/app_localizations.dart';
import 'package:myapp/utils/bounding_box_painter.dart';
import 'package:myapp/utils/object_detector.dart';
import 'package:myapp/components/settings_dialog.dart';
import 'package:provider/provider.dart';
import 'package:myapp/utils/language_provider.dart';
import 'package:myapp/utils/theme_provider.dart';

class DetectionResult {
  final List<ImageLabel> labels;
  final List<DetectedObject> detectedObjects;
  final String imagePath;
  final DateTime timestamp;
  final Size? imageSize;
  final InputImageRotation? rotation;

  DetectionResult({
    required this.labels,
    this.detectedObjects = const [],
    required this.imagePath,
    required this.timestamp,
    this.imageSize,
    this.rotation,
  });
}

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<ImageLabel> _detectedLabels = [];
  List<DetectedObject> _detectedObjects = [];
  String? _error;
  Timer? _timer;
  double _confidenceThreshold = 0.6;
  bool _flashEnabled = false;
  ResolutionPreset _currentResolution = ResolutionPreset.medium;
  final List<DetectionResult> _detectionHistory = [];
  bool _isPaused = false;
  String? _capturedImagePath;
  Size? _imageSize;
  InputImageRotation? _imageRotation;
  bool _showBoundingBoxes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLabeler();
    _initializeObjectDetector();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _disposeResources();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _disposeResources() async {
    try {
      _timer?.cancel();
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
    } catch (e) {
      print('Error disposing resources: $e');
    }
  }

  Future<void> _initializeLabeler() async {
    final options =
        ImageLabelerOptions(confidenceThreshold: _confidenceThreshold);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _initializeObjectDetector() async {
    try {
      _objectDetector = await ObjectDetector.getInstance();
    } catch (e) {
      print('Error initializing object detector: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize object detector: $e';
        });
      }
    }
  }

  Future<bool> _safeCameraOperation(Future<void> Function() operation) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        setState(() {
          _error = appLocalizations.cameraNotReady;
        });
      }
      return false;
    }

    try {
      await operation();
      return true;
    } catch (e) {
      print('Camera operation error: $e');
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        setState(() {
          _error = '${appLocalizations.photoFailed}: $e';
        });
      }
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    await _disposeResources();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras available.';
        });
        return;
      }

      CameraDescription? rearCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      if (rearCamera == null) {
        setState(() {
          _error = 'No rear camera found.';
        });
        return;
      }

      _cameraController = CameraController(
        rearCamera,
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (_flashEnabled &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      if (!_isPaused && mounted) {
        _startImageProcessingTimer();
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize camera: ${e.toString()}';
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _startImageProcessingTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isProcessing &&
          _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_isPaused &&
          mounted) {
        _captureAndProcessImage();
      }
    });
  }

  Future<void> _updateCameraResolution(ResolutionPreset newResolution) async {
    if (_currentResolution == newResolution) return;

    _timer?.cancel();
    await _cameraController?.dispose();

    setState(() {
      _currentResolution = newResolution;
      _isCameraInitialized = false;
    });

    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _flashEnabled = !_flashEnabled;
      await _cameraController!
          .setFlashMode(_flashEnabled ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  void _togglePause() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
      } else {
        _startImageProcessingTimer();
      }
    });
  }

  Future<void> _updateConfidenceThreshold(double newThreshold) async {
    if (_confidenceThreshold == newThreshold) return;

    setState(() {
      _confidenceThreshold = newThreshold;
    });

    await _imageLabeler?.close();

    final options =
        ImageLabelerOptions(confidenceThreshold: _confidenceThreshold);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _captureAndProcessImage() async {
    if (_isProcessing || _imageLabeler == null) {
      return;
    }

    _isProcessing = true;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw CameraException('not_initialized', 'Camera is not ready');
      }

      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);
      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler!.processImage(inputImage);

      List<DetectedObject> objects = [];
      if (_objectDetector != null) {
        objects = await _objectDetector!.processImage(inputImage);
        _imageSize = _objectDetector!.imageSize;
        _imageRotation = _objectDetector!.rotation;
      }

      if (mounted) {
        setState(() {
          _detectedLabels = labels;
          _detectedObjects = objects;
          _capturedImagePath = imageFile.path;
        });
      }

      await file.delete();
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            appLocalizations.cameraNotReady,
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 2),
        ));
      }
      return;
    }

    _isProcessing = true;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initializeCamera();
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          throw CameraException(
              'not_initialized', 'Camera could not be initialized');
        }
      }

      final bool wasPaused = _isPaused;
      if (!wasPaused) {
        _togglePause();
      }

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw CameraException('not_initialized', 'Camera is not ready');
      }

      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            appLocalizations.takingPhoto,
            style: const TextStyle(fontSize: 16),
          ),
          duration: const Duration(milliseconds: 500),
        ));
      }

      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await file.copy('${appDir.path}/$filename');

      if (_imageLabeler == null) {
        throw Exception('Image labeler not initialized');
      }

      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler!.processImage(inputImage);

      List<DetectedObject> objects = [];
      Size? imageSize;
      InputImageRotation? rotation;

      if (_objectDetector != null) {
        objects = await _objectDetector!.processImage(inputImage);
        imageSize = _objectDetector!.imageSize;
        rotation = _objectDetector!.rotation;
      }

      if (mounted) {
        setState(() {
          _detectionHistory.add(DetectionResult(
            labels: labels,
            detectedObjects: objects,
            imagePath: savedImage.path,
            timestamp: DateTime.now(),
            imageSize: imageSize,
            rotation: rotation,
          ));

          _detectedLabels = labels;
          _detectedObjects = objects;
          _imageSize = imageSize;
          _imageRotation = rotation;
        });

        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${appLocalizations.photoSaved} (${labels.length} ${appLocalizations.objectsDetected})',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }

      await file.delete();

      if (mounted &&
          !wasPaused &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _togglePause();
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${appLocalizations.photoFailed}: ${e.toString().split(':').first}',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _showHistoryDialog(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    if (_detectionHistory.isEmpty) {
      ScaffoldMessenger.of(this.context)
          .showSnackBar(SnackBar(content: Text(appLocalizations.noPhotos)));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(appLocalizations.detectionHistory),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    )
                  ],
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _detectionHistory.length,
                    itemBuilder: (BuildContext listContext, index) {
                      final item = _detectionHistory[
                          _detectionHistory.length - 1 - index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(item.imagePath),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          item.labels.isNotEmpty
                              ? item.labels.first.label
                              : appLocalizations.unknownObject,
                          style: MyTextStyle.size15
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.labels.length} ${appLocalizations.objects} - ${_formatDateTime(item.timestamp)}',
                          style: MyTextStyle.size12,
                        ),
                        onTap: () {
                          _showImageDetailsDialog(dialogContext, item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageDetailsDialog(BuildContext context, DetectionResult result) {
    final appLocalizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(_formatDateTime(result.timestamp)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stack to overlay the image with bounding boxes
                    Stack(
                      children: [
                        // The image
                        Image.file(
                          File(result.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),

                        // Bounding boxes if available
                        if (_showBoundingBoxes &&
                            result.detectedObjects.isNotEmpty &&
                            result.imageSize != null &&
                            result.rotation != null)
                          CustomPaint(
                            painter: BoundingBoxPainter(
                              objects: result.detectedObjects,
                              absoluteImageSize: result.imageSize!,
                              rotation: result.rotation!,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: MediaQuery.of(dialogContext).size.width *
                                  result.imageSize!.height /
                                  result.imageSize!.width,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                        '${appLocalizations.detectedObjects}: ${result.labels.length}',
                        style: MyTextStyle.size15
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...result.labels.map((label) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label.label, style: MyTextStyle.size15),
                            Text(
                              '${(label.confidence * 100).toStringAsFixed(1)}%',
                              style: MyTextStyle.size15,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _disposeResources();
    _imageLabeler?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/icons/object.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(appLocalizations.appName),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $_error',
              style: MyTextStyle.size18.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/icons/object.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(appLocalizations.appName),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/object.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(appLocalizations.appName),
          ],
        ),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: appLocalizations.history,
          ),
          // Flash button
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: appLocalizations.flash,
          ),
          // Bounding box toggle
          IconButton(
            icon: Icon(
                _showBoundingBoxes ? Icons.border_all : Icons.border_clear),
            onPressed: _toggleBoundingBoxes,
            tooltip: 'Toggle Bounding Boxes',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
            tooltip: appLocalizations.settings,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // Camera preview
          CameraPreview(_cameraController!),

          // Bounding box overlay for live detection
          if (_showBoundingBoxes &&
              _detectedObjects.isNotEmpty &&
              _imageSize != null &&
              _imageRotation != null)
            CustomPaint(
              painter: BoundingBoxPainter(
                objects: _detectedObjects,
                absoluteImageSize: _imageSize!,
                rotation: _imageRotation!,
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Pause overlay
          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  size: 80,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),

          // Bottom control panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Control buttons
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pause/Resume button
                      IconButton(
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _togglePause,
                      ),

                      // Take photo button
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white30,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      // Empty space for balance
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Detection results panel
                Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${appLocalizations.detectedObjects}: ${_detectedLabels.length}',
                            style: MyTextStyle.size18
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            '${appLocalizations.confidence}: ${(_confidenceThreshold * 100).toInt()}%',
                            style: MyTextStyle.size12
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._detectedLabels.map((label) {
                        // Color based on confidence
                        final confidence = label.confidence;
                        Color confidenceColor;
                        if (confidence > 0.8) {
                          confidenceColor = Colors.green;
                        } else if (confidence > 0.6) {
                          confidenceColor = Colors.yellow;
                        } else {
                          confidenceColor = Colors.orange;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label.label,
                                  style: MyTextStyle.size15
                                      .copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(label.confidence * 100).toStringAsFixed(1)}%',
                                style: MyTextStyle.size15
                                    .copyWith(color: confidenceColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SettingsDialog();
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _toggleBoundingBoxes() {
    setState(() {
      _showBoundingBoxes = !_showBoundingBoxes;
    });
  }
}
