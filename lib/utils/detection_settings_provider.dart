import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetectionSettingsProvider extends ChangeNotifier {
  // Default values
  double _confidenceThreshold = 0.6;
  ResolutionPreset _cameraResolution = ResolutionPreset.medium;

  // Storage keys
  static const String _thresholdKey = 'confidence_threshold';
  static const String _resolutionKey = 'camera_resolution';

  // Getters
  double get confidenceThreshold => _confidenceThreshold;
  ResolutionPreset get cameraResolution => _cameraResolution;

  DetectionSettingsProvider() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load threshold
    final savedThreshold = prefs.getDouble(_thresholdKey);
    if (savedThreshold != null) {
      _confidenceThreshold = savedThreshold;
    }

    // Load resolution
    final savedResolution = prefs.getInt(_resolutionKey);
    if (savedResolution != null) {
      _cameraResolution = _intToResolutionPreset(savedResolution);
    }

    notifyListeners();
  }

  Future<void> setConfidenceThreshold(double threshold) async {
    if (_confidenceThreshold == threshold) return;

    _confidenceThreshold = threshold;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, threshold);

    notifyListeners();
  }

  Future<void> setCameraResolution(ResolutionPreset resolution) async {
    if (_cameraResolution == resolution) return;

    _cameraResolution = resolution;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resolutionKey, _resolutionPresetToInt(resolution));

    notifyListeners();
  }

  // Helper methods to convert between ResolutionPreset and int for storage
  int _resolutionPresetToInt(ResolutionPreset resolution) {
    switch (resolution) {
      case ResolutionPreset.low:
        return 0;
      case ResolutionPreset.medium:
        return 1;
      case ResolutionPreset.high:
        return 2;
      case ResolutionPreset.veryHigh:
        return 3;
      case ResolutionPreset.ultraHigh:
        return 4;
      case ResolutionPreset.max:
        return 5;
      default:
        return 1; // Default to medium
    }
  }

  ResolutionPreset _intToResolutionPreset(int value) {
    switch (value) {
      case 0:
        return ResolutionPreset.low;
      case 1:
        return ResolutionPreset.medium;
      case 2:
        return ResolutionPreset.high;
      case 3:
        return ResolutionPreset.veryHigh;
      case 4:
        return ResolutionPreset.ultraHigh;
      case 5:
        return ResolutionPreset.max;
      default:
        return ResolutionPreset.medium;
    }
  }
}
