import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/vet_contact.dart';
import '../widgets/app_ui.dart';

class VetContactsScreen extends StatefulWidget {
  const VetContactsScreen({super.key});

  @override
  State<VetContactsScreen> createState() => _VetContactsScreenState();
}

class _VetContactsScreenState extends State<VetContactsScreen> {
  final _db = DatabaseService();

  void _showAddEditDialog({VetContact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final specCtrl = TextEditingController(text: existing?.specialty ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(existing == null ? 'Add Vet Contact' : 'Edit Contact', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Vet Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specCtrl,
              decoration: InputDecoration(
                labelText: 'Specialty (optional)',
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                try {
                  final contact = VetContact(
                    id: existing?.id ?? '',
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    specialty: specCtrl.text.isEmpty ? null : specCtrl.text,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                    createdAt: DateTime.now(),
                  );
                  if (existing == null) {
                    await _db.addVetContact(contact);
                  } else {
                    await _db.updateVetContact(existing.id, contact);
                  }
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) {
                    showDialog(context: ctx, builder: (_) => AlertDialog(title: const Text('Error'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
                  }
                }
              },
              style: primaryButtonStyle(),
              child: Text(existing == null ? 'Add contact' : 'Update contact'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vet Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        
        
        elevation: 0,
      ),
      body: StreamBuilder<List<VetContact>>(
        stream: _db.getVetContactsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data ?? [];
          if (contacts.isEmpty) {
            return const EmptyState(
              icon: Icons.contact_phone_outlined,
              title: 'No vet contacts yet',
              message: 'Tap + to add your veterinarian',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final vet = contacts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const IconTile(Icons.medical_services_outlined),
                  title: Text(vet.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: context.mutedText),
                          const SizedBox(width: 4),
                          Text(vet.phone, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (vet.specialty != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(vet.specialty!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Call',
                        icon: const Icon(Icons.call_outlined, color: AppConstants.primaryColor, size: 22),
                        onPressed: () => launchUrl(Uri.parse('tel:${vet.phone}')),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') _showAddEditDialog(existing: vet);
                          if (val == 'delete') _db.deleteVetContact(vet.id);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppConstants.dangerColor))),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
