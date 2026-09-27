import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true)
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => File(f.path))
      .toList();

  int fixed = 0;
  
  for (final file in files) {
    String content = file.readAsStringSync();
    final original = content;

    // Fix all "const Something(...Theme.of(context)..." patterns
    // We need to remove 'const' before any expression containing Theme.of(context)
    
    // Pattern: const TextStyle(...Theme.of(context)...)
    final constRegex = RegExp(r'const\s+(TextStyle|BoxDecoration|Icon|BackButton|EdgeInsets|InputDecoration|CircleAvatar)\(');
    
    // For each const match, check if the expression contains Theme.of(context)
    // If so, remove 'const'
    var matches = constRegex.allMatches(content).toList().reversed;
    for (final match in matches) {
      // Find the matching closing paren
      int start = match.start;
      int parenStart = match.end - 1;
      int depth = 1;
      int pos = parenStart + 1;
      while (pos < content.length && depth > 0) {
        if (content[pos] == '(') depth++;
        if (content[pos] == ')') depth--;
        pos++;
      }
      
      final expr = content.substring(start, pos);
      if (expr.contains('Theme.of(context)')) {
        // Remove 'const '
        content = content.substring(0, start) + content.substring(start).replaceFirst('const ', '');
        fixed++;
      }
    }
    
    // Also fix const list literals containing Theme.of
    // e.g., const [SomeWidget(Theme.of(context)...)]
    content = content.replaceAllMapped(
      RegExp(r'const\s+\[([^\]]*Theme\.of\(context\)[^\]]*)\]'),
      (m) => '[${m.group(1)}]'
    );

    if (content != original) {
      file.writeAsStringSync(content);
    }
  }
  
  print('Fixed $fixed const issues');
}
