import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:myapp/utils/detection_settings_provider.dart';
import 'package:myapp/utils/app_localizations.dart';
import 'package:provider/provider.dart';

class DetectionSettings extends StatelessWidget {
  const DetectionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final detectionSettings = Provider.of<DetectionSettingsProvider>(context);
    final appLocalizations = AppLocalizations.of(context);

    return ExpansionTile(
      leading: const Icon(Icons.settings_applications),
      title: Text(
        appLocalizations.objectDetectionSettings,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      children: [
        // Confidence Threshold Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.confidenceThreshold,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                appLocalizations.higherValueExplanation,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('30%'),
                  Expanded(
                    child: Slider(
                      value: detectionSettings.confidenceThreshold,
                      min: 0.3,
                      max: 0.9,
                      divisions: 6,
                      label:
                          '${(detectionSettings.confidenceThreshold * 100).toInt()}%',
                      onChanged: (value) {
                        detectionSettings.setConfidenceThreshold(value);
                      },
                    ),
                  ),
                  Text('90%'),
                ],
              ),
            ],
          ),
        ),

        const Divider(),

        // Camera Resolution
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.cameraResolution,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                appLocalizations.resolutionExplanation,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),

              // Low Resolution Option
              _buildResolutionOption(
                context,
                ResolutionPreset.low,
                appLocalizations.lowResolution,
                appLocalizations.lowResolutionDesc,
                detectionSettings,
              ),

              const SizedBox(height: 8),

              // Medium Resolution Option
              _buildResolutionOption(
                context,
                ResolutionPreset.medium,
                appLocalizations.mediumResolution,
                appLocalizations.mediumResolutionDesc,
                detectionSettings,
              ),

              const SizedBox(height: 8),

              // High Resolution Option
              _buildResolutionOption(
                context,
                ResolutionPreset.high,
                appLocalizations.highResolution,
                appLocalizations.highResolutionDesc,
                detectionSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionOption(
    BuildContext context,
    ResolutionPreset resolution,
    String title,
    String description,
    DetectionSettingsProvider settings,
  ) {
    final isSelected = settings.cameraResolution == resolution;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        settings.setCameraResolution(resolution);
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<ResolutionPreset>(
              value: resolution,
              groupValue: settings.cameraResolution,
              onChanged: (ResolutionPreset? value) {
                if (value != null) {
                  settings.setCameraResolution(value);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
