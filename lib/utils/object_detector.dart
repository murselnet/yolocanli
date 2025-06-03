import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart'
    hide InputImageRotation;
import 'package:myapp/utils/bounding_box_painter.dart';
import 'package:myapp/utils/detection_settings_provider.dart';

class ObjectDetector {
  ObjectDetector._();

  static ObjectDetector? _instance;
  ImageLabeler? _imageLabeler;
  bool _isClosed = false;
  List<DetectedObject> _detectedObjects = [];
  Size? _imageSize;
  InputImageRotation? _rotation;
  final Random _random = Random();
  double _confidenceThreshold = 0.7;
  DetectionSettingsProvider? _settingsProvider;

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

  void updateSettingsProvider(DetectionSettingsProvider provider) {
    _settingsProvider = provider;
    _updateConfidenceThreshold(provider.confidenceThreshold);
  }

  Future<void> _updateConfidenceThreshold(double threshold) async {
    if (_confidenceThreshold == threshold) return;

    _confidenceThreshold = threshold;

    try {
      await _imageLabeler?.close();
      final options =
          ImageLabelerOptions(confidenceThreshold: _confidenceThreshold);
      _imageLabeler = ImageLabeler(options: options);
    } catch (e) {
      print('Error updating confidence threshold: $e');
      // Fallback to base image labeler
      _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    }
  }

  Future<void> _initialize() async {
    // Initialize image labeler with default confidence threshold
    try {
      final options =
          ImageLabelerOptions(confidenceThreshold: _confidenceThreshold);
      _imageLabeler = ImageLabeler(options: options);
    } catch (e) {
      print('Error initializing ImageLabeler: $e');
      // Fallback to base image labeler
      _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    }
  }

  Future<List<DetectedObject>> processImage(InputImage inputImage) async {
    if (_imageLabeler == null || _isClosed) {
      return [];
    }

    // Update threshold if settings provider exists
    if (_settingsProvider != null &&
        _confidenceThreshold != _settingsProvider!.confidenceThreshold) {
      await _updateConfidenceThreshold(_settingsProvider!.confidenceThreshold);
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
    try {
      await _imageLabeler!.close();
    } catch (e) {
      print('Error closing image labeler: $e');
    }
  }
}
