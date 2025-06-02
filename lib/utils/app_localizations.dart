import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      // General
      'appName': 'YoloCanli',
      'subtitle': 'Real-time Object Detection',

      // Object Detection Screen
      'detectedObjects': 'Detected Objects',
      'confidence': 'Confidence',
      'history': 'History',
      'flash': 'Flash',
      'settings': 'Settings',
      'noPhotos': 'No saved photos yet.',
      'takingPhoto': 'Taking photo...',
      'photoSaved': 'Photo saved',
      'objectsDetected': 'objects detected',
      'photoFailed': 'Failed to take photo',
      'cameraNotReady': 'Camera is not ready, please wait a few seconds.',

      // History Dialog
      'detectionHistory': 'Detection History',
      'unknownObject': 'Unknown object',
      'objects': 'objects',

      // Settings Dialog
      'objectDetectionSettings': 'Object Detection Settings',
      'confidenceThreshold': 'Confidence Threshold',
      'higherValueExplanation':
          'Higher value means more certainty, but fewer detections',
      'cameraResolution': 'Camera Resolution',
      'resolutionExplanation':
          'Higher resolution provides better detection but slower performance',
      'lowResolution': 'Low (fast)',
      'lowResolutionDesc': 'Battery saving, smoother experience',
      'mediumResolution': 'Medium (balanced)',
      'mediumResolutionDesc': 'Balance of speed and quality',
      'highResolution': 'High (more accurate)',
      'highResolutionDesc': 'Best detection, slower processing',
      'cancel': 'Cancel',
      'apply': 'Apply',
    },
    'tr': {
      // Genel
      'appName': 'YoloCanli',
      'subtitle': 'Gerçek Zamanlı Nesne Algılama',

      // Nesne Algılama Ekranı
      'detectedObjects': 'Algılanan Nesneler',
      'confidence': 'Güvenilirlik',
      'history': 'Geçmiş',
      'flash': 'Flaş',
      'settings': 'Ayarlar',
      'noPhotos': 'Henüz kaydedilmiş bir fotoğraf yok.',
      'takingPhoto': 'Fotoğraf çekiliyor...',
      'photoSaved': 'Fotoğraf kaydedildi',
      'objectsDetected': 'nesne algılandı',
      'photoFailed': 'Fotoğraf çekilemedi',
      'cameraNotReady':
          'Kamera henüz hazırlanıyor, lütfen birkaç saniye bekleyin.',

      // Geçmiş Diyaloğu
      'detectionHistory': 'Tespit Geçmişi',
      'unknownObject': 'Bilinmeyen nesne',
      'objects': 'nesne',

      // Ayarlar Diyaloğu
      'objectDetectionSettings': 'Nesne Algılama Ayarları',
      'confidenceThreshold': 'Güvenilirlik Eşiği',
      'higherValueExplanation':
          'Daha yüksek değer daha kesin, ancak daha az nesne algılar',
      'cameraResolution': 'Kamera Çözünürlüğü',
      'resolutionExplanation':
          'Yüksek çözünürlük daha iyi algılama sağlar ancak daha yavaş çalışır',
      'lowResolution': 'Düşük (hızlı)',
      'lowResolutionDesc': 'Pil tasarrufu, daha akıcı deneyim',
      'mediumResolution': 'Orta (dengeli)',
      'mediumResolutionDesc': 'Hız ve kalite dengesi',
      'highResolution': 'Yüksek (daha kesin)',
      'highResolutionDesc': 'En iyi algılama, daha yavaş işlem',
      'cancel': 'İptal',
      'apply': 'Uygula',
    }
  };

  String get appName => _localizedValues[locale.languageCode]!['appName']!;
  String get subtitle => _localizedValues[locale.languageCode]!['subtitle']!;
  String get detectedObjects =>
      _localizedValues[locale.languageCode]!['detectedObjects']!;
  String get confidence =>
      _localizedValues[locale.languageCode]!['confidence']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get flash => _localizedValues[locale.languageCode]!['flash']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get noPhotos => _localizedValues[locale.languageCode]!['noPhotos']!;
  String get takingPhoto =>
      _localizedValues[locale.languageCode]!['takingPhoto']!;
  String get photoSaved =>
      _localizedValues[locale.languageCode]!['photoSaved']!;
  String get objectsDetected =>
      _localizedValues[locale.languageCode]!['objectsDetected']!;
  String get photoFailed =>
      _localizedValues[locale.languageCode]!['photoFailed']!;
  String get cameraNotReady =>
      _localizedValues[locale.languageCode]!['cameraNotReady']!;
  String get detectionHistory =>
      _localizedValues[locale.languageCode]!['detectionHistory']!;
  String get unknownObject =>
      _localizedValues[locale.languageCode]!['unknownObject']!;
  String get objects => _localizedValues[locale.languageCode]!['objects']!;
  String get objectDetectionSettings =>
      _localizedValues[locale.languageCode]!['objectDetectionSettings']!;
  String get confidenceThreshold =>
      _localizedValues[locale.languageCode]!['confidenceThreshold']!;
  String get higherValueExplanation =>
      _localizedValues[locale.languageCode]!['higherValueExplanation']!;
  String get cameraResolution =>
      _localizedValues[locale.languageCode]!['cameraResolution']!;
  String get resolutionExplanation =>
      _localizedValues[locale.languageCode]!['resolutionExplanation']!;
  String get lowResolution =>
      _localizedValues[locale.languageCode]!['lowResolution']!;
  String get lowResolutionDesc =>
      _localizedValues[locale.languageCode]!['lowResolutionDesc']!;
  String get mediumResolution =>
      _localizedValues[locale.languageCode]!['mediumResolution']!;
  String get mediumResolutionDesc =>
      _localizedValues[locale.languageCode]!['mediumResolutionDesc']!;
  String get highResolution =>
      _localizedValues[locale.languageCode]!['highResolution']!;
  String get highResolutionDesc =>
      _localizedValues[locale.languageCode]!['highResolutionDesc']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get apply => _localizedValues[locale.languageCode]!['apply']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
