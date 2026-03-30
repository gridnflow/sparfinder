import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _zipController;

  static const _popularCities = {
    'Berlin': '10115',
    'Hamburg': '20095',
    'München': '80331',
    'Köln': '50667',
    'Frankfurt': '60311',
    'Stuttgart': '70173',
    'Düsseldorf': '40213',
    'Leipzig': '04109',
  };

  @override
  void initState() {
    super.initState();
    _zipController =
        TextEditingController(text: ref.read(zipCodeProvider));
  }

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

  void _saveZip(String zip) {
    if (zip.length != 5 || int.tryParse(zip) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte eine gültige 5-stellige Postleitzahl eingeben'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ref.read(zipCodeProvider.notifier).state = zip;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('zipCode', zip);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PLZ $zip gespeichert'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentZip = ref.watch(zipCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PLZ Sektion
          const Text(
            'Standort',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Postleitzahl (PLZ)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aktuell: $currentZip',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: const InputDecoration(
                            hintText: '10115',
                            prefixIcon: Icon(Icons.location_on),
                            counterText: '',
                          ),
                          onSubmitted: _saveZip,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _saveZip(_zipController.text),
                        child: const Text('Speichern'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 빠른 도시 선택
          const Text(
            'Schnellauswahl',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _popularCities.entries.map((entry) {
                final isSelected = entry.value == currentZip;
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('PLZ ${entry.value}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.primaryGreen)
                      : null,
                  onTap: () {
                    _zipController.text = entry.value;
                    _saveZip(entry.value);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // 법적 정보
          const Text(
            'Rechtliches',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppTheme.primaryGreen),
                  title: const Text('Datenschutzerklärung'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => launchUrl(
                    Uri.parse('https://yeongsHub.github.io/sparfinder/datenschutz.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined,
                      color: AppTheme.primaryGreen),
                  title: const Text('Nutzungsbedingungen'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => launchUrl(
                    Uri.parse('https://yeongsHub.github.io/sparfinder/nutzungsbedingungen.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 앱 정보
          const Text(
            'Über die App',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AngebotsFuchs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AngebotsFuchs vergleicht Preise von ALDI, LIDL, REWE, Kaufland, Penny, Netto und vielen weiteren Supermärkten in Deutschland.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
