import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../services/database_service.dart';
import '../models/cow.dart';
import '../widgets/error_dialog.dart';

import 'confirm_image_screen.dart';

class AddCowScreen extends StatefulWidget {
  final Cow? existingCow;
  const AddCowScreen({super.key, this.existingCow});

  @override
  State<AddCowScreen> createState() => _AddCowScreenState();
}

class _AddCowScreenState extends State<AddCowScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  String _healthStatus = 'Healthy';
  String _cowType = 'Cow';
  bool _isBornInFarm = false;
  String? _motherCowId;
  DateTime? _dob;
  List<Cow> _availableMothers = [];

  List<File> _images = [];
  List<String> _existingUrls = [];
  final _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCow != null) {
      final cow = widget.existingCow!;
      _tagController.text = cow.tagNumber;
      _nameController.text = cow.name ?? '';
      _breedController.text = cow.breed ?? '';
      _ageController.text = cow.age?.toString() ?? '';
      _healthStatus = cow.healthStatus;
      _cowType = cow.cowType;
      _isBornInFarm = cow.isBornInFarm ?? false;
      _motherCowId = cow.motherCowId;
      _dob = cow.dob;
      _existingUrls = cow.imageUrls ?? (cow.imageUrl != null ? [cow.imageUrl!] : []);
    } else {
      _fetchNextTag();
    }
    _fetchMothers();
  }

  Future<void> _fetchNextTag() async {
    try {
      final nextTag = await _db.getNextCowTag();
      if (mounted) {
        setState(() {
          _tagController.text = nextTag;
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _fetchMothers() async {
    try {
      final allCows = await _db.getCows();
      if (mounted) {
        setState(() {
          _availableMothers = allCows.where((c) => c.cowType != 'Bull' && c.cowType != 'Calf').toList();
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _processImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _processImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      if (mounted) {
        final bool? confirmed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConfirmImageScreen(imageFile: file)),
        );
        if (confirmed == true) {
          setState(() => _images.add(file));
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      List<String> allUrls = List.from(_existingUrls);
      
      if (_images.isNotEmpty) {
        final newUrls = await _db.uploadMultipleCowImages(_images, _tagController.text);
        allUrls.addAll(newUrls);
      }

      final cow = Cow(
        id: widget.existingCow?.id ?? '', 
        tagNumber: _tagController.text,
        name: _nameController.text.isEmpty ? null : _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text),
        healthStatus: _healthStatus,
        imageUrl: allUrls.isNotEmpty ? allUrls.first : null,
        imageUrls: allUrls.isNotEmpty ? allUrls : null,
        createdAt: widget.existingCow?.createdAt ?? DateTime.now(),
        cowType: _cowType,
        isBornInFarm: _cowType == 'Calf' ? _isBornInFarm : null,
        motherCowId: (_cowType == 'Calf' && _isBornInFarm) ? _motherCowId : null,
        dob: (_cowType == 'Calf' && _isBornInFarm) ? _dob : null,
      );

      if (widget.existingCow != null) {
        await _db.updateCow(cow);
      } else {
        await _db.addCow(cow);
        HapticFeedback.selectionClick();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingCow != null ? 'Edit Cow' : 'Register New Cow')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingUrls.map((url) => _buildImageThumbnail(url, isNetwork: true)),
                    ..._images.map((file) => _buildImageThumbnail(file.path, isNetwork: false)),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppConstants.controlRadius),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppConstants.primaryColor),
                            SizedBox(height: 4),
                            Text('Add Photo', style: TextStyle(fontSize: 12, color: AppConstants.primaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag Number (e.g. KRB-101)', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nickname (Optional, e.g. Daisy)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed (e.g. Jersey, Holstein)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              if (!(_cowType == 'Calf' && _isBornInFarm)) ...[
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: (_cowType == 'Calf' && !_isBornInFarm) ? 'Approximate Age (Months/Years)' : 'Age (Years)', 
                    border: const OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                value: _cowType,
                decoration: const InputDecoration(labelText: 'Animal Type', border: OutlineInputBorder()),
                items: ['Cow', 'Buffalo', 'Calf', 'Heifer', 'Bull'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() {
                  _cowType = val!;
                  if (_cowType != 'Calf') {
                    _isBornInFarm = false;
                    _motherCowId = null;
                  }
                }),
              ),
              if (_cowType == 'Calf') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  value: _isBornInFarm,
                  decoration: const InputDecoration(labelText: 'Origin', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: false, child: Text('Other / Purchased')),
                    DropdownMenuItem(value: true, child: Text('Born in Farm')),
                  ],
                  onChanged: (val) => setState(() {
                    _isBornInFarm = val!;
                    if (!_isBornInFarm) _motherCowId = null;
                  }),
                ),
              ],
              if (_cowType == 'Calf' && _isBornInFarm) ...[
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_dob == null ? 'Select Date of Birth' : 'DOB: ${DateFormat('yyyy-MM-dd').format(_dob!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dob ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dob = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _motherCowId,
                  decoration: const InputDecoration(labelText: 'Mother Cow', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Mother')),
                    ..._availableMothers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.tagNumber} (${c.breed ?? "Native"})'))),
                  ],
                  onChanged: (val) => setState(() => _motherCowId = val),
                  validator: (val) => (_cowType == 'Calf' && _isBornInFarm && val == null) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _healthStatus,
                decoration: const InputDecoration(labelText: 'Health Status', border: OutlineInputBorder()),
                items: ['Healthy', 'Under Treatment', 'Sick', 'Dry'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _healthStatus = val!),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: primaryButtonStyle(),
                child: _isSaving ? const ButtonSpinner() : Text(widget.existingCow != null ? 'Save changes' : 'Register cow'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String path, {required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: ResizeImage(
                isNetwork ? CachedNetworkImageProvider(path) : FileImage(File(path)) as ImageProvider,
                width: (120 * MediaQuery.of(context).devicePixelRatio).round(),
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isNetwork) {
                  _existingUrls.remove(path);
                } else {
                  _images.removeWhere((f) => f.path == path);
                }
              });
            },
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black.withOpacity(0.6),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
