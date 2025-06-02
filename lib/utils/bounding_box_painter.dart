import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

// Custom class to represent a detected object
class DetectedObject {
  final Rect boundingBox;
  final List<ObjectLabel> labels;

  DetectedObject({
    required this.boundingBox,
    required this.labels,
  });
}

// Custom label class
class ObjectLabel {
  final String text;
  final double confidence;

  ObjectLabel({
    required this.text,
    required this.confidence,
  });
}

// Custom input image rotation enum
enum InputImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

class BoundingBoxPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final bool showLabels;

  BoundingBoxPainter({
    required this.objects,
    required this.absoluteImageSize,
    required this.rotation,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    final Paint background = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black54;

    for (final DetectedObject detectedObject in objects) {
      // Calculate coordinates based on the rotation
      final Rect transformedRect = _transformRect(
        rect: detectedObject.boundingBox,
        imageSize: absoluteImageSize,
        widgetSize: size,
        rotation: rotation,
      );

      // Draw bounding box
      canvas.drawRect(transformedRect, paint);

      // Draw labels if enabled
      if (showLabels && detectedObject.labels.isNotEmpty) {
        final ObjectLabel label = detectedObject.labels.first;
        final double confidence = label.confidence;
        final String text =
            '${label.text} ${(confidence * 100).toStringAsFixed(1)}%';

        final TextSpan span = TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        );

        final TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );

        tp.layout();

        // Text background
        final Rect textBackgroundRect = Rect.fromLTWH(
          transformedRect.left,
          transformedRect.top - tp.height - 4,
          tp.width + 8,
          tp.height + 4,
        );
        canvas.drawRect(textBackgroundRect, background);

        // Text
        tp.paint(
          canvas,
          Offset(transformedRect.left + 4, transformedRect.top - tp.height - 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.objects != objects;
  }

  Rect _transformRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    // Account for rotation if needed
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return Rect.fromLTRB(
          widgetSize.width - rect.bottom * scaleX,
          rect.left * scaleY,
          widgetSize.width - rect.top * scaleX,
          rect.right * scaleY,
        );
      case InputImageRotation.rotation180deg:
        return Rect.fromLTRB(
          widgetSize.width - rect.right * scaleX,
          widgetSize.height - rect.bottom * scaleY,
          widgetSize.width - rect.left * scaleX,
          widgetSize.height - rect.top * scaleY,
        );
      case InputImageRotation.rotation270deg:
        return Rect.fromLTRB(
          rect.top * scaleX,
          widgetSize.height - rect.right * scaleY,
          rect.bottom * scaleX,
          widgetSize.height - rect.left * scaleY,
        );
      case InputImageRotation.rotation0deg:
      default:
        return Rect.fromLTRB(
          rect.left * scaleX,
          rect.top * scaleY,
          rect.right * scaleX,
          rect.bottom * scaleY,
        );
    }
  }
}
