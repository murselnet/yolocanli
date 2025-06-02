import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:myapp/screen/object_detection_screen.dart';
import 'package:myapp/utils/my_text_style.dart'; // Import MyTextStyle
import 'package:myapp/utils/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Ensure portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Auto-navigate to object detection screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ObjectDetectionScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Attractive gradient background
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.teal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // App Logo with animation
              FadeTransition(
                opacity: _opacityAnimation,
                child: Image.asset(
                  'assets/icons/object.png', // Make sure you have this asset
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              // App Title with animation
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  appLocalizations.appName,
                  style: MyTextStyle.size32.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ), // Use MyTextStyle
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle with animation
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  appLocalizations.subtitle,
                  style: MyTextStyle.size18.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
