import 'package:flutter/material.dart';
import 'package:myapp/utils/language_provider.dart';
import 'package:myapp/utils/app_localizations.dart';
import 'package:provider/provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appLocalizations = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(
        'Language / Dil',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        languageProvider.isCurrentLanguage('en') ? 'English' : 'Türkçe',
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.arrow_drop_down),
        onSelected: (String value) {
          languageProvider.changeLanguage(Locale(value));
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'en',
            child: Row(
              children: [
                if (languageProvider.isCurrentLanguage('en'))
                  Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  ),
                const SizedBox(width: 8),
                const Text('English'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'tr',
            child: Row(
              children: [
                if (languageProvider.isCurrentLanguage('tr'))
                  Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  ),
                const SizedBox(width: 8),
                const Text('Türkçe'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
