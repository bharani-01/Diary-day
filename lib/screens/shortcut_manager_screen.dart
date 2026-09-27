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
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Drag to reorder. Use the switch to show or hide a shortcut on the dashboard.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        children: allKeys.map((key) {
          final isSelected = sp.selectedShortcuts.contains(key);
          final data = ShortcutProvider.allShortcuts[key]!;
          final onSurface = Theme.of(context).colorScheme.onSurface;
          
          return Card(
            key: ValueKey(key),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.transparent,
              leading: Icon(
                data['icon'] as IconData,
                color: isSelected ? AppConstants.primaryColor : onSurface.withOpacity(0.45),
              ),
              title: Text(
                lp.translate(key),
                style: TextStyle(color: isSelected ? onSurface : onSurface.withOpacity(0.6)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: isSelected,
                    activeColor: AppConstants.primaryColor,
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
                  Icon(Icons.drag_handle, color: onSurface.withOpacity(0.4)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
