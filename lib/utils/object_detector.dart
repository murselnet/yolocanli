import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart'
    hide InputImageRotation;
import 'package:myapp/utils/bounding_box_painter.dart';

class ObjectDetector {
  ObjectDetector._();

  static ObjectDetector? _instance;
  ImageLabeler? _imageLabeler;
  bool _isClosed = false;
  List<DetectedObject> _detectedObjects = [];
  Size? _imageSize;
  InputImageRotation? _rotation;
  final Random _random = Random();

  static Future<ObjectDetector> getInstance() async {
    if (_instance == null) {
      _instance = ObjectDetector._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  List<DetectedObject> get detectedObjects => _detectedObjects;
  Size? get imageSize => _imageSize;
  InputImageRotation? get rotation => _rotation;

  Future<void> _initialize() async {
    // Initialize image labeler with high confidence threshold
    final options = ImageLabelerOptions(confidenceThreshold: 0.7);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<List<DetectedObject>> processImage(InputImage inputImage) async {
    if (_imageLabeler == null || _isClosed) {
      return [];
    }

    try {
      // Get image labels
      final labels = await _imageLabeler!.processImage(inputImage);

      // Store image size and rotation
      _imageSize = inputImage.metadata?.size;

      // Default to rotation0deg if no rotation metadata
      _rotation = InputImageRotation.rotation0deg;

      // If no size info, use default size
      _imageSize ??= const Size(480, 640);

      // Clear previous objects
      _detectedObjects = [];

      // Create simulated bounding boxes for each label
      for (int i = 0; i < labels.length; i++) {
        final label = labels[i];

        // Create a simulated bounding box for each label
        // This creates rectangles of different sizes at different positions
        final width = _imageSize!.width / (2 + _random.nextDouble() * 2);
        final height = _imageSize!.height / (2 + _random.nextDouble() * 2);
        final left = _random.nextDouble() * (_imageSize!.width - width);
        final top = _random.nextDouble() * (_imageSize!.height - height);

        final rect = Rect.fromLTWH(left, top, width, height);

        // Create object label
        final objectLabel = ObjectLabel(
          text: label.label,
          confidence: label.confidence,
        );

        // Create detected object
        final detectedObject = DetectedObject(
          boundingBox: rect,
          labels: [objectLabel],
        );

        _detectedObjects.add(detectedObject);
      }

      return _detectedObjects;
    } catch (e) {
      print('Error in object detection simulation: $e');
      return [];
    }
  }

  Future<void> close() async {
    if (_imageLabeler == null || _isClosed) return;

    _isClosed = true;
    await _imageLabeler!.close();
  }
}
