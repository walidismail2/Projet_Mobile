import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';
import 'package:flutter_example/core/widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = Session.instance.currentUser!;
    _name = TextEditingController(text: u.name);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phone);
    _address = TextEditingController(text: u.address);
    _photoPath = u.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Photo de profil',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Tu pourras recentrer / recadrer ensuite'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.crop_rounded),
                title: const Text('Recadrer la photo actuelle'),
                onTap: () => Navigator.pop(ctx, 'recrop'),
              ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.reminder),
                title: const Text('Supprimer la photo'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'remove') {
      setState(() => _photoPath = null);
      return;
    }

    String? sourcePath = _photoPath;
    if (action == 'gallery' || action == 'camera') {
      final picked = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;
      sourcePath = picked.path;
    }
    if (sourcePath == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      maxWidth: 1200,
      maxHeight: 1200,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer / recentrer',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Recadrer / recentrer',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null || !mounted) return;
    setState(() => _photoPath = cropped.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final current = Session.instance.currentUser!;
    final address = _address.text.trim();
    double? lat = current.latitude;
    double? lon = current.longitude;
    var clearCoords = false;

    if (address.isEmpty) {
      clearCoords = true;
      lat = null;
      lon = null;
    } else if (address != current.address || !current.hasCoordinates) {
      try {
        final point = await GeocodingService().geocodeAddress(address);
        lat = point.latitude;
        lon = point.longitude;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Adresse / GPS non reconnus. Ex. 36,6833, 10,3007',
              ),
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }
    }

    await Session.instance.updateLocalProfile(
      current.copyWith(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: address,
        latitude: lat,
        longitude: lon,
        photoPath: _photoPath,
        clearCoordinates: clearCoords,
        clearPhoto: _photoPath == null,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnack(context, 'Profil mis à jour (SQLite)');
  }

  AppUser get _previewUser {
    final current = Session.instance.currentUser!;
    return current.copyWith(
      name: _name.text.trim().isEmpty ? current.name : _name.text.trim(),
      photoPath: _photoPath,
      clearPhoto: _photoPath == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations personnelles')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _choosePhoto,
                child: UserAvatar(_previewUser, size: 100, bordered: true),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ajouter / recentrer la photo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Galerie ou appareil photo → recadrage circulaire',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Nom',
              hint: 'Nom',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            LabeledField(
              label: 'E-mail',
              hint: 'email',
              controller: _email,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
            ),
            LabeledField(
              label: 'Téléphone',
              hint: 'Tél',
              controller: _phone,
            ),
            LabeledField(
              label: 'Adresse ou coordonnées',
              hint: 'Ex. ESPRIT Ariana  ou  36,6833, 10,3007',
              controller: _address,
              maxLines: 2,
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
