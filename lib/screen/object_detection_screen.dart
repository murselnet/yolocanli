import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
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
    _initializeCamera();
    _initializeImageLabeler();
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Use a compatible format
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

  Future<void> _initializeImageLabeler() async {
    // Load the custom model. For this example, we'll use a base model.
    // For a custom model, you would need to provide the model file path.
    // final modelPath = await _getModelPath('path/to/your/model.tflite');
    // final options = LocalLabelerOptions(modelPath: modelPath);
    // _imageLabeler = ImageLabeler(options: options);

    // Using a general base model for demonstration
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<String> _getModelPath(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final byteData = await rootBundle.load(assetPath);
    await File(path).writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return path;
  }


  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessing || _imageLabeler == null) {
      return;
    }

    _isProcessing = true;

    // Convert CameraImage to InputImage
    final InputImage inputImage = _inputImageFromCameraImage(cameraImage);

    try {
      final List<ImageLabel> labels = await _imageLabeler!.processImage(inputImage);
      if(mounted) {
        setState(() {
          _detectedLabels = labels;
        });
      }
    } catch (e) {
      print('Error processing image: $e');
       if(mounted) {
         setState(() {
            _error = 'Failed to process image: ${e.toString()}';
         });
       }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _inputImageFromCameraImage(CameraImage cameraImage) {
    // Based on the example in google_mlkit_image_labeling documentation
    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(cameraImage.planes[0].bytesPerRow) ??
            InputImageRotation.rotation0deg;


    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(cameraImage.format.raw) ??
            InputImageFormat.nv21;

    final planeData = cameraImage.planes.map(
      (Plane plane) => InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      ),
    ).toList();

    final inputImageData = InputImageData(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage = InputImage.fromBytes(
      bytes: cameraImage.planes[0].bytes,
      inputImageData: inputImageData,
    );

    return inputImage;
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


    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
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
        title: const Text('Object Detection'),
        backgroundColor: Colors.blueGrey[900],
        iconTheme: const IconThemeData(color: Colors.white70), // White icons for dark theme
        titleTextStyle: MyTextStyle.size21.copyWith(color: Colors.white), // White title
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54, // Semi-transparent background
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: _detectedLabels.isEmpty
                  ? Text(
                      'Detecting objects...',
                      style: MyTextStyle.size18.copyWith(color: Colors.white70),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _detectedLabels.map((label) {
                          return Text(
                            '${label.label}: ${(label.confidence * 100).toStringAsFixed(2)}%',
                            style: MyTextStyle.size18.copyWith(color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to get rotation from raw value
extension InputImageRotationValue on InputImageRotation {
  static InputImageRotation? fromRawValue(int rawValue) {
    switch (rawValue) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }
}

// Helper to get format from raw value
extension InputImageFormatValue on InputImageFormat {
  static InputImageFormat? fromRawValue(int rawValue) {
    switch (rawValue) {
      case 35:
        return InputImageFormat.nv21; // Example for Android, might need adjustment
      default:
        return null;
    }
  }
}
