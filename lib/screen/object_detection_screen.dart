import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
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
        ResolutionPreset.high, // Use high resolution as per the prompt
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _cameraController!.startImageStream(_processCameraImage);

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

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessing || _imageLabeler == null) {
      return;
    }

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(cameraImage);

      if (inputImage != null) {
        final labels = await _imageLabeler!.processImage(inputImage);

        if (mounted) {
          setState(() {
            _detectedLabels = labels;
          });
        }
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

  InputImage? _convertCameraImageToInputImage(CameraImage cameraImage) {
    try {
      final camera = _cameraController?.description;
      if (camera == null) return null;

      // Convert to InputImage format
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Get image rotation
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      // Get image format
      final format =
          InputImageFormatValue.fromRawValue(cameraImage.format.raw) ??
              InputImageFormat.nv21;

      // Create InputImage
      final inputImageData = InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: imageRotation,
        format: format,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection'),
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
          title: const Text('Object Detection'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/object.png',
              width: 24,
              height: 24,
            ),
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
        ],
      ),
    );
  }
}
