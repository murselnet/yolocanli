# YoloCanli - Real-time Object Detection

YoloCanli is a Flutter application that performs real-time object detection using the device camera and Google's ML Kit for image labeling. The app has a clean, modern UI with a splash screen and a main detection screen.

## Features

- Real-time object detection using ML Kit
- Clean, modern Material Design interface
- Splash screen with animation
- Semi-transparent bottom sheet to display detection results
- Portrait mode only orientation

## Screenshots

(Screenshots of the app in action would be placed here)

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- VS Code with Flutter and Dart extensions

### Installation

1. Clone the repository:
```
git clone https://github.com/yourusername/yolocanli.git
```

2. Navigate to the project directory:
```
cd yolocanli
```

3. Install dependencies:
```
flutter pub get
```

4. Run the app:
```
flutter run
```

## App Usage

1. Upon launching the app, a splash screen will appear for 3 seconds.
2. The app will then transition to the object detection screen.
3. The camera will start automatically and begin detecting objects.
4. Detected objects and their confidence levels will be displayed in the bottom sheet.
5. The app requires camera permissions which should be granted when prompted.

## Technical Details

- Platform Support:
  - Android: minSdkVersion 21+
  - iOS: iOS 11.0+
- The app uses ML Kit's image labeling API with a confidence threshold of 0.5.
- Camera frames are processed in real-time to provide immediate detection results.

## Dependencies

- flutter: sdk: flutter
- cupertino_icons: ^1.0.8
- google_mlkit_image_labeling: ^0.13.0
- camera: ^0.11.1
- path_provider: ^2.1.5
- path: ^1.9.1

## Project Structure

```
/lib
  /screen
    - splash_screen.dart
    - object_detection_screen.dart
  /utils
    - my_text_style.dart
  - main.dart
/assets
  /fonts
    - Poppins-Regular.ttf
  /icons
    - object.png
```
