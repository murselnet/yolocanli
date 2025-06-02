import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:myapp/utils/my_text_style.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  ImageLabeler? _imageLabeler;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<ImageLabel> _detectedLabels = [];
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeLabeler();
    _initializeCamera();
  }

  Future<void> _initializeLabeler() async {
    // Define the labeler options with confidence threshold of 0.5
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras available.';
        });
        return;
      }

      // Find a rear camera
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
        ResolutionPreset
            .medium, // Düşük çözünürlük kullanarak performansı artır
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // JPEG formatını kullan
      );

      await _cameraController!.initialize();

      // Sürekli akış yerine belirli aralıklarla fotoğraf çek
      _startImageProcessingTimer();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _error = 'Failed to initialize camera: ${e.toString()}';
      });
    }
  }

  void _startImageProcessingTimer() {
    // Her 1 saniyede bir görüntü işle
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isProcessing &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _captureAndProcessImage();
      }
    });
  }

  Future<void> _captureAndProcessImage() async {
    if (_isProcessing || _imageLabeler == null) {
      return;
    }

    _isProcessing = true;

    try {
      // Kameradan fotoğraf çek
      final XFile imageFile = await _cameraController!.takePicture();

      // XFile'ı bir File'a dönüştür
      final File file = File(imageFile.path);

      // File'ı bir InputImage'a dönüştür
      final inputImage = InputImage.fromFile(file);

      // Görüntüyü işle
      final labels = await _imageLabeler!.processImage(inputImage);

      // Geçici dosyayı sil
      await file.delete();

      if (mounted) {
        setState(() {
          _detectedLabels = labels;
        });
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to process image: ${e.toString()}';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/icons/object.png', width: 24, height: 24),
              const SizedBox(width: 8),
              const Text('YoloCanli'),
            ],
          ),
          backgroundColor: Colors.blueGrey[900],
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
              const Text('YoloCanli'),
            ],
          ),
          backgroundColor: Colors.blueGrey[900],
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
            const Text('YoloCanli'),
          ],
        ),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Stack(
        children: <Widget>[
          CameraPreview(_cameraController!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54, // Semi-transparent bottom sheet
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Objects: ${_detectedLabels.length}',
                    style: MyTextStyle.size18.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ..._detectedLabels.map((label) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${label.label}: ${(label.confidence * 100).toStringAsFixed(1)}%',
                        style: MyTextStyle.size15.copyWith(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
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
}
