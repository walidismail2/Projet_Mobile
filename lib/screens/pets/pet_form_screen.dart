import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

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

  bool get _isEdit => widget.pet != null;

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
      if (_isEdit) {
        await _repo.update(pet);
      } else {
        await _repo.insert(pet);
      }
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
                onTap: () async {
                  final f = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (f != null) setState(() => _photoPath = f.path);
                },
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
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
                child: Text('Ajouter une photo',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final (name, emoji) in _species)
                  ChoiceChip(
                    label: Text('$emoji $name'),
                    selected: _selectedSpecies == name,
                    onSelected: (_) =>
                        setState(() => _selectedSpecies = name),
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
            LabeledField(
              label: 'Race',
              hint: 'Golden Retriever',
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
