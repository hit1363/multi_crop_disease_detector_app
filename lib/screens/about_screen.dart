import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_localizations.dart';

const String _trainingRepoUrl =
    'https://github.com/hit1363/An-Efficient-Multi-Crop-Leaf-Disease-Detection-System';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('about')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.eco,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.text('app_title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.text('offline_description')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.text('disclaimer')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.code),
              title: Text(strings.text('about_training_repo')),
              subtitle: Text(strings.text('about_training_repo_desc')),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse(_trainingRepoUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
