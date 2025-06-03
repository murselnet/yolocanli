import 'package:flutter/material.dart';
import 'package:myapp/utils/theme_provider.dart';
import 'package:myapp/utils/app_localizations.dart';
import 'package:provider/provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appLocalizations = AppLocalizations.of(context);

    // Define theme color swatches
    final Map<AppTheme, Color> themeColors = {
      AppTheme.defaultDark: Colors.blue,
      AppTheme.nightBlue: Colors.indigo,
      AppTheme.tealAccent: Colors.teal,
      AppTheme.purpleDream: Colors.purple,
    };

    // Define theme names
    final Map<AppTheme, String> themeNames = {
      AppTheme.defaultDark: 'Default Dark',
      AppTheme.nightBlue: 'Night Blue',
      AppTheme.tealAccent: 'Teal Accent',
      AppTheme.purpleDream: 'Purple Dream',
    };

    return ExpansionTile(
      leading: const Icon(Icons.color_lens),
      title: Text(
        'Theme',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(themeNames[themeProvider.currentTheme]!),
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppTheme.values.length,
            itemBuilder: (context, index) {
              final theme = AppTheme.values[index];
              final isSelected = themeProvider.currentTheme == theme;

              return GestureDetector(
                onTap: () {
                  themeProvider.setTheme(theme);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 44,
                  decoration: BoxDecoration(
                    color: themeColors[theme],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeColors[theme]!.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
