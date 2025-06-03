import 'package:flutter/material.dart';
import 'package:myapp/utils/app_localizations.dart';
import 'package:myapp/components/language_selector.dart';
import 'package:myapp/components/theme_selector.dart';
import 'package:myapp/components/detection_settings.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        appLocalizations.settings,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageSelector(),
            Divider(),
            ThemeSelector(),
            Divider(),
            DetectionSettings(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            appLocalizations.apply,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
