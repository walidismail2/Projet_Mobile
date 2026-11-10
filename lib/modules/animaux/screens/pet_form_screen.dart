import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/app_exception.dart';
import 'package:flutter_example/modules/animaux/services/breed_api_service.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet;
  const PetFormScreen({super.key, this.pet});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  static const _species = [
    ('Chien', '🐶'),
    ('Chat', '🐱'),
    ('Lapin', '🐰'),
    ('Oiseau', '🐦'),
    ('Poisson', '🐠'),
    ('Autre', '🐾'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _repo = PetRepository();
  final _breedApi = BreedApiService();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _birth;
  late final TextEditingController _weight;
  late final TextEditingController _chip;
  late String _selectedSpecies;
  late String _sex;
  late bool _sterilized;
  String? _photoPath;
  bool _saving = false;

  List<BreedInfo> _apiBreeds = [];
  BreedInfo? _selectedApiBreed;
  String? _breedImageUrl;
  bool _breedsLoading = false;
  String? _breedsError;

  bool get _isEdit => widget.pet != null;
  bool get _supportsBreedApi =>
      _selectedSpecies == 'Chien' || _selectedSpecies == 'Chat';

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _selectedSpecies = p?.species ?? 'Chien';
    _sex = p?.sex ?? 'Mâle';
    _sterilized = p?.sterilized ?? false;
    _photoPath = p?.photoPath;
    _name = TextEditingController(text: p?.name ?? '');
    _breed = TextEditingController(text: p?.breed ?? '');
    _birth = TextEditingController(text: p?.birthDate ?? '');
    _weight = TextEditingController(text: p?.weight.toString() ?? '');
    _chip = TextEditingController(text: p?.chip ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBreeds());
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _birth.dispose();
    _weight.dispose();
    _chip.dispose();
    super.dispose();
  }

  String get _emoji =>
      _species.firstWhere((e) => e.$1 == _selectedSpecies).$2;

  Color get _color => switch (_selectedSpecies) {
        'Chien' => const Color(0xFFFFB74D),
        'Chat' => const Color(0xFF9FA8DA),
        'Lapin' => const Color(0xFFA5D6A7),
        _ => AppColors.primaryLight,
      };

  Future<void> _loadBreeds() async {
    if (!_supportsBreedApi) {
      setState(() {
        _apiBreeds = [];
        _selectedApiBreed = null;
        _breedImageUrl = null;
        _breedsLoading = false;
        _breedsError = null;
      });
      return;
    }

    setState(() {
      _breedsLoading = true;
      _breedsError = null;
      _apiBreeds = [];
      _selectedApiBreed = null;
      _breedImageUrl = null;
    });

    try {
      final breeds = await _breedApi.fetchBreeds(_selectedSpecies);
      if (!mounted) return;
      BreedInfo? match;
      final current = _breed.text.trim().toLowerCase();
      if (current.isNotEmpty) {
        for (final b in breeds) {
          if (b.name.toLowerCase() == current) {
            match = b;
            break;
          }
        }
      }
      setState(() {
        _apiBreeds = breeds;
        _selectedApiBreed = match;
        _breedsLoading = false;
      });
      if (match != null) {
        await _loadBreedImage(match);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _breedsLoading = false;
        _breedsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _breedsLoading = false;
        _breedsError = 'Erreur réseau lors du chargement des races.';
      });
    }
  }

  Future<void> _loadBreedImage(BreedInfo breed) async {
    setState(() => _breedImageUrl = null);
    final url = await _breedApi.fetchBreedImage(breed);
    if (!mounted || _selectedApiBreed?.name != breed.name) return;
    setState(() => _breedImageUrl = url);
  }

  Future<void> _onSpeciesSelected(String name) async {
    if (_selectedSpecies == name) return;
    setState(() {
      _selectedSpecies = name;
      if (name != 'Chien' && name != 'Chat') {
        // garder la saisie libre pour les autres espèces
      } else {
        _breed.clear();
      }
    });
    await _loadBreeds();
  }

  Future<void> _onBreedPicked(BreedInfo breed) async {
    setState(() {
      _selectedApiBreed = breed;
      _breed.text = breed.name;
    });
    await _loadBreedImage(breed);
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
                'Photo de l’animal',
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final birth = _birth.text.trim();
      final pet = Pet(
        id: widget.pet?.id,
        ownerId: Session.instance.userId!,
        name: _name.text.trim(),
        species: _selectedSpecies,
        breed: _breed.text.trim(),
        age: Pet.ageFromBirthDate(birth),
        weight: double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0,
        sex: _sex,
        emoji: _emoji,
        color: _color,
        birthDate: birth,
        chip: _chip.text.trim().isEmpty ? '—' : _chip.text.trim(),
        sterilized: _sterilized,
        photoPath: _photoPath,
      );
      final Pet saved;
      if (_isEdit) {
        await _repo.update(pet);
        saved = pet;
      } else {
        saved = await _repo.insert(pet);
      }
      await LocalNotifications.instance
          .scheduleBirthday(pet: saved, recordInApp: true);
      if (!mounted) return;
      Navigator.pop(context);
      showSuccessSnack(
          context, _isEdit ? 'Modifications enregistrées' : 'Animal ajouté');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier' : 'Ajouter un animal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _choosePhoto,
                child: PetAvatar(
                  Pet(
                    ownerId: '',
                    name: '',
                    species: _selectedSpecies,
                    breed: '',
                    age: '',
                    weight: 0,
                    sex: _sex,
                    emoji: _emoji,
                    color: _color,
                    birthDate: '',
                    chip: '',
                    sterilized: false,
                    photoPath: _photoPath,
                  ),
                  size: 100,
                  bordered: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
                child: Text('Ajouter / recentrer la photo',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
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
            Wrap(
              spacing: 8,
              children: [
                for (final (name, emoji) in _species)
                  ChoiceChip(
                    label: Text('$emoji $name'),
                    selected: _selectedSpecies == name,
                    onSelected: (_) => _onSpeciesSelected(name),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Nom',
              hint: 'Rocky',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            if (_supportsBreedApi) ...[
              _BreedApiSection(
                species: _selectedSpecies,
                loading: _breedsLoading,
                error: _breedsError,
                breeds: _apiBreeds,
                selected: _selectedApiBreed,
                imageUrl: _breedImageUrl,
                breedController: _breed,
                onRetry: _loadBreeds,
                onPicked: _onBreedPicked,
              ),
            ] else
              LabeledField(
                label: 'Race',
                hint: 'Nain / Canari…',
                controller: _breed,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Race requise' : null,
              ),
            LabeledField(
              label: 'Date de naissance',
              hint: 'JJ/MM/AAAA',
              controller: _birth,
              readOnly: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Date requise' : null,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDate: DateTime.now()
                      .subtract(const Duration(days: 365)),
                );
                if (d != null) {
                  _birth.text =
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                  setState(() {});
                }
              },
            ),
            if (_birth.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Âge calculé : ${Pet.ageFromBirthDate(_birth.text)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            LabeledField(
              label: 'Poids (kg)',
              hint: '28.5',
              controller: _weight,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null
                      ? 'Poids invalide'
                      : null,
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Mâle'),
                  selected: _sex == 'Mâle',
                  onSelected: (_) => setState(() => _sex = 'Mâle'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Femelle'),
                  selected: _sex == 'Femelle',
                  onSelected: (_) => setState(() => _sex = 'Femelle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LabeledField(
                label: 'Puce', hint: '250 …', controller: _chip),
            SwitchListTile(
              value: _sterilized,
              onChanged: (v) => setState(() => _sterilized = v),
              title: const Text('Stérilisé(e)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Enregistrer' : "Ajouter l'animal"),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreedApiSection extends StatelessWidget {
  final String species;
  final bool loading;
  final String? error;
  final List<BreedInfo> breeds;
  final BreedInfo? selected;
  final String? imageUrl;
  final TextEditingController breedController;
  final VoidCallback onRetry;
  final ValueChanged<BreedInfo> onPicked;

  const _BreedApiSection({
    required this.species,
    required this.loading,
    required this.error,
    required this.breeds,
    required this.selected,
    required this.imageUrl,
    required this.breedController,
    required this.onRetry,
    required this.onPicked,
  });

  String get _apiLabel =>
      species == 'Chien' ? 'Dog CEO API' : 'The Cat API';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Race (API externe)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _apiLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          AppCard(
            color: const Color(0xFFFFF0F2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error!, style: const TextStyle(color: AppColors.reminder)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
                LabeledField(
                  label: 'Saisie manuelle',
                  hint: 'Race',
                  controller: breedController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Race requise' : null,
                ),
              ],
            ),
          )
        else ...[
          Autocomplete<BreedInfo>(
            key: ValueKey('breeds-$species-${breeds.length}'),
            displayStringForOption: (b) => b.name,
            optionsBuilder: (textEditingValue) {
              final q = textEditingValue.text.trim().toLowerCase();
              if (q.isEmpty) return breeds.take(40);
              return breeds
                  .where((b) => b.name.toLowerCase().contains(q))
                  .take(40);
            },
            onSelected: onPicked,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              // Keep form controller in sync with autocomplete field.
              if (controller.text != breedController.text &&
                  breedController.text.isNotEmpty &&
                  controller.text.isEmpty) {
                controller.text = breedController.text;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: species == 'Chien'
                      ? 'Ex. Golden Retriever'
                      : 'Ex. Maine Coon',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Recharger l’API',
                    onPressed: onRetry,
                    icon: const Icon(Icons.cloud_download_outlined),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Race requise' : null,
                onChanged: (v) => breedController.text = v,
                onFieldSubmitted: (_) => onSubmit(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(option.name),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (selected != null)
            AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: imageUrl == null
                          ? Container(
                              color: AppColors.primaryLight,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.primaryLight,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Photo d’exemple via $_apiLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sauvegardée en SQLite à l’enregistrement',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
