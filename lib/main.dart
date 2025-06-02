import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:myapp/screen/splash_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp`
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching cameras: ${e.code}: ${e.description}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YoloCanli', // Replace with your app name
      theme: ThemeData(
        brightness: Brightness.dark, // Dark theme
        primarySwatch: Colors.blue, // Blue accent color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define the default TextTheme to use the Poppins font
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Poppins',
        ),
        appBarTheme: AppBarTheme(
           backgroundColor: Colors.blueGrey[900], // Dark AppBar background
           foregroundColor: Colors.white, // White text/icons on AppBar
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
