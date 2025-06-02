import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:myapp/utils/my_text_style.dart';

class DetectionResult {
  final List<ImageLabel> labels;
  final String imagePath;
  final DateTime timestamp;

  DetectionResult({
    required this.labels,
    required this.imagePath,
    required this.timestamp,
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
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<ImageLabel> _detectedLabels = [];
  String? _error;
  Timer? _timer;
  double _confidenceThreshold = 0.6; // Güven eşiği
  bool _flashEnabled = false;
  ResolutionPreset _currentResolution = ResolutionPreset.medium;
  List<DetectionResult> _detectionHistory = [];
  bool _isPaused = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLabeler();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // Geçersiz bir kontrolcü varsa erken çık
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    // Uygulama arka plana geçtiğinde kamera ve timer kaynaklarını temizle
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _disposeResources();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama geri geldiğinde kamerayı yeniden başlat
      _initializeCamera();
    }
  }

  // Kaynakları güvenli bir şekilde temizle
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
    // Güven eşiği ile etiketleyici oluştur
    final options =
        ImageLabelerOptions(confidenceThreshold: _confidenceThreshold);
    _imageLabeler = ImageLabeler(options: options);
  }

  // Güvenli bir şekilde kamera işlemlerini başlatma
  Future<bool> _safeCameraOperation(Future<void> Function() operation) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        setState(() {
          _error = 'Kamera hazır değil. Lütfen uygulamayı yeniden başlatın.';
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
        setState(() {
          _error = 'Kamera işlemi başarısız: $e';
        });
      }
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    // Eğer halihazırda başlatılmış bir kamera varsa, önce onu temizleyelim
    await _disposeResources();

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
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Flash modu ayarla
      if (_flashEnabled &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      // Sürekli akış yerine belirli aralıklarla fotoğraf çek
      if (!_isPaused && mounted) {
        _startImageProcessingTimer();
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _error = null; // Hata durumunu temizle
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
    // Varolan timer'ı temizle
    _timer?.cancel();

    // Her 0.8 saniyede bir görüntü işle
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

    // Timer'ı durdur
    _timer?.cancel();

    // Önceki controller'ı temizle
    await _cameraController?.dispose();

    setState(() {
      _currentResolution = newResolution;
      _isCameraInitialized = false;
    });

    // Kamera yeniden başlat
    await _initializeCamera();
  }

  // Flash durumunu değiştir
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      _flashEnabled = !_flashEnabled;
      await _cameraController!
          .setFlashMode(_flashEnabled ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  // Pause/Resume işlemi
  void _togglePause() {
    // Kamera durumunu kontrol et
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

  // Güven eşiğini güncelle ve yeni etiketleyici oluştur
  Future<void> _updateConfidenceThreshold(double newThreshold) async {
    if (_confidenceThreshold == newThreshold) return;

    setState(() {
      _confidenceThreshold = newThreshold;
    });

    // Eski etiketleyiciyi kapat
    await _imageLabeler?.close();

    // Yeni etiketleyici oluştur
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
      // Kamera kontrolünü doğrula
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw CameraException('not_initialized', 'Kamera hazır değil');
      }

      // Kameradan fotoğraf çek
      final XFile imageFile = await _cameraController!.takePicture();

      // XFile'ı bir File'a dönüştür
      final File file = File(imageFile.path);

      // File'ı bir InputImage'a dönüştür
      final inputImage = InputImage.fromFile(file);

      // Görüntüyü işle
      final labels = await _imageLabeler!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedLabels = labels;
          // Fotoğraf çekildi ve işlendi, _capturedImagePath'i güncelle (son resim)
          _capturedImagePath = imageFile.path;
        });
      }

      // Geçici dosyayı sil
      await file.delete();
    } catch (e) {
      print('Error processing image: $e');
      // Sürekli hata göstermeyelim, sessizce işleme devam edelim
    } finally {
      _isProcessing = false;
    }
  }

  // Fotoğraf çek ve geçmişe kaydet
  Future<void> _takePhoto() async {
    // İşlem başladığında kameranın durumunu kontrol et
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
            content: Text(
                'Kamera hazır değil veya işlem devam ediyor, lütfen bekleyin.')));
      }
      return;
    }

    _isProcessing = true; // İşlem sırasında diğer istekleri engelle

    try {
      // Kamerayı duraklatın
      final bool wasPaused = _isPaused;
      if (!wasPaused) {
        _togglePause();
      }

      // Kamera kontrolünü tekrar kontrol et
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw CameraException('not_initialized', 'Kamera hazır değil');
      }

      // Fotoğraf çek
      final XFile imageFile = await _cameraController!.takePicture();

      // XFile'ı bir File'a dönüştür
      final File file = File(imageFile.path);

      // Kalıcı depolama dizini alın
      final appDir = await getApplicationDocumentsDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await file.copy('${appDir.path}/$filename');

      // Kamera kontrolünü tekrar kontrol et
      if (_imageLabeler == null) {
        throw Exception('Image labeler not initialized');
      }

      // Görüntüyü işle
      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler!.processImage(inputImage);

      // Geçmişe ekle - sadece hala ekli isek
      if (mounted) {
        setState(() {
          _detectionHistory.add(DetectionResult(
            labels: labels,
            imagePath: savedImage.path,
            timestamp: DateTime.now(),
          ));

          // Anlık sonucu da güncelle
          _detectedLabels = labels;
        });

        // Mesaj göster
        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
            content: Text(
                'Fotoğraf kaydedildi ve ${labels.length} nesne tespit edildi.')));
      }

      // Geçici dosyayı sil
      await file.delete();

      // Kamerayı önceki durumuna getir - sadece hala ekli isek
      if (mounted &&
          !wasPaused &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _togglePause();
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('Fotoğraf çekilirken hata oluştu: $e')));
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Geçmiş fotoğrafları göster
  void _showHistoryDialog(BuildContext context) {
    if (_detectionHistory.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Henüz kaydedilmiş bir fotoğraf yok.')));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Tespit Geçmişi'),
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
                          '${item.labels.isNotEmpty ? item.labels.first.label : "Bilinmeyen nesne"}',
                          style: MyTextStyle.size15
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.labels.length} nesne - ${_formatDateTime(item.timestamp)}',
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

  // Görüntü detaylarını göster
  void _showImageDetailsDialog(BuildContext context, DetectionResult result) {
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
                    Image.file(
                      File(result.imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    Text('Tespit Edilen Nesneler (${result.labels.length}):',
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
                                style: MyTextStyle.size15),
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
        actions: [
          // Fotoğraf geçmişi butonu
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: 'Geçmiş',
          ),
          // Flash butonu
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Flash',
          ),
          // Ayarlar butonu
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          CameraPreview(_cameraController!),

          // Pause/Play overlay
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

          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Butonlar satırı
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pause/Resume butonu
                      IconButton(
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _togglePause,
                      ),

                      // Fotoğraf çekme butonu
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

                      // Boş, sadece düzen için
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Tespit sonuçları
                Container(
                  width: double.infinity,
                  color: Colors.black54, // Semi-transparent bottom sheet
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detected Objects: ${_detectedLabels.length}',
                            style: MyTextStyle.size18
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            'Confidence: ${(_confidenceThreshold * 100).toInt()}%',
                            style: MyTextStyle.size12
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._detectedLabels.map((label) {
                        // Güven oranına göre renk değiştir
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
                                  '${label.label}',
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

  // Ayarlar dialog penceresini göster
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Detection Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Güven eşiği ayarı
                  Text(
                      'Confidence Threshold: ${(_confidenceThreshold * 100).toInt()}%',
                      style: MyTextStyle.size15),
                  Slider(
                    value: _confidenceThreshold,
                    min: 0.3,
                    max: 0.9,
                    divisions: 6,
                    onChanged: (value) {
                      setDialogState(() {
                        _confidenceThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Çözünürlük ayarı
                  Text('Camera Resolution:', style: MyTextStyle.size15),
                  const SizedBox(height: 8),
                  DropdownButton<ResolutionPreset>(
                    value: _currentResolution,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: ResolutionPreset.low,
                        child: Text('Low (faster)', style: MyTextStyle.size15),
                      ),
                      DropdownMenuItem(
                        value: ResolutionPreset.medium,
                        child: Text('Medium (balanced)',
                            style: MyTextStyle.size15),
                      ),
                      DropdownMenuItem(
                        value: ResolutionPreset.high,
                        child: Text('High (more accurate)',
                            style: MyTextStyle.size15),
                      ),
                    ],
                    onChanged: (ResolutionPreset? value) {
                      if (value != null) {
                        setDialogState(() {
                          _currentResolution = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    _updateConfidenceThreshold(_confidenceThreshold);
                    _updateCameraResolution(_currentResolution);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Tarih formatını düzenle
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
