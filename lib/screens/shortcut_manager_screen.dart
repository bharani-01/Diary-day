import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/shortcut_provider.dart';
import '../services/language_provider.dart';
import '../constants.dart';

class ShortcutManagerScreen extends StatelessWidget {
  const ShortcutManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<ShortcutProvider>(context);
    final lp = Provider.of<LanguageProvider>(context);
    final allKeys = ShortcutProvider.allShortcuts.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customize Shortcuts')),
      body: ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final List<String> items = List.from(sp.selectedShortcuts);
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
          sp.updateShortcuts(items);
        },
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Drag to reorder. Tap the switch to show/hide on Home.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        children: allKeys.map((key) {
          final isSelected = sp.selectedShortcuts.contains(key);
          final data = ShortcutProvider.allShortcuts[key]!;
          
          return Card(
            key: ValueKey(key),
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected ? Colors.white : Colors.grey.shade50,
            child: ListTile(
              leading: Icon(data['icon'] as IconData, color: data['color'] as Color),
              title: Text(lp.translate(key)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: isSelected,
                    onChanged: (val) {
                      final List<String> newList = List.from(sp.selectedShortcuts);
                      if (val) {
                        newList.add(key);
                      } else {
                        newList.remove(key);
                      }
                      sp.updateShortcuts(newList);
                    },
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
