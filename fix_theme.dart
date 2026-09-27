import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).where((f) => f.path.endsWith('.dart') && File(f.path).existsSync());
  
  int count = 0;
  for (final f in files) {
    final file = File(f.path);
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('backgroundColor: AppConstants.backgroundColor')) {
      content = content.replaceAll('backgroundColor: AppConstants.backgroundColor', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
      changed = true;
    }
    
    if (content.contains('backgroundColor: Colors.white')) {
      content = content.replaceAll('backgroundColor: Colors.white', 'backgroundColor: Theme.of(context).colorScheme.surface');
      changed = true;
    }

    if (content.contains('color: Colors.white')) {
      content = content.replaceAll(
        'decoration: BoxDecoration(\n        color: Colors.white,', 
        'decoration: BoxDecoration(\n        color: Theme.of(context).colorScheme.surface,'
      );
      content = content.replaceAll(
        'decoration: BoxDecoration(color: Colors.white', 
        'decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface'
      );
      changed = true;
    }

    if (content.contains('color: Colors.black87')) {
      content = content.replaceAll('color: Colors.black87', 'color: Theme.of(context).colorScheme.onSurface');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      count++;
    }
  }
  print('Fixed $count files');
}
