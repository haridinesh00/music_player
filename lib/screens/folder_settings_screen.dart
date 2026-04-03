import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';

class FolderSettingsScreen extends StatelessWidget {
  const FolderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Specific Folders'),
        actions: [
          if (lib.allowedFolders.isNotEmpty)
            TextButton(
              onPressed: () async {
                // Clear all filters (scans everything)
                for (var folder in List.from(lib.allowedFolders)) {
                  await lib.toggleFolder(folder, false);
                }
              },
              child: const Text('Reset'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select the folders you want to fetch music from. If no folders are selected, the app will scan your entire device.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lib.allAvailableFolders.length,
              itemBuilder: (context, index) {
                final folderPath = lib.allAvailableFolders[index];
                final folderName = folderPath.split('/').last;
                final isSelected = lib.allowedFolders.contains(folderPath);

                return CheckboxListTile(
                  title: Text(
                    folderName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    folderPath,
                    style: TextStyle(fontSize: 11, color: cs.primary),
                  ),
                  value: isSelected,
                  activeColor: cs.primary,
                  onChanged: (bool? value) {
                    if (value != null) {
                      lib.toggleFolder(folderPath, value);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}