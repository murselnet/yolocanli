import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:myapp/screen/splash_screen.dart';
import 'package:myapp/utils/language_provider.dart';
import 'package:myapp/utils/theme_provider.dart';
import 'package:myapp/utils/detection_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/utils/app_localizations.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    // Ensure that plugin services are initialized so that `availableCameras()`
    // can be called before `runApp`
    WidgetsFlutterBinding.ensureInitialized();

    // Ensure portrait mode only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    try {
      cameras = await availableCameras();
      print('Found ${cameras.length} cameras');
    } on CameraException catch (e) {
      print('Error in fetching cameras: ${e.code}: ${e.description}');
      // Allow app to continue without cameras
      cameras = [];
    } catch (e) {
      print('Unexpected error with cameras: $e');
      // Allow app to continue without cameras
      cameras = [];
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => DetectionSettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Fatal error in app initialization: $e');
    // Show error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Uygulama başlatılırken bir hata oluştu.\nLütfen tekrar deneyin veya uygulama geliştiricisiyle iletişime geçin.\nHata: $e',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'yolocanli',
      theme: themeProvider.getThemeData(),
      locale: languageProvider.currentLocale,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('tr', ''),
      ],
    );
  }
}
