import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
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

  late String _selectedSpecies = widget.pet?.species ?? 'Chien';
  late String _sex = widget.pet?.sex ?? 'Mâle';
  late bool _sterilized = widget.pet?.sterilized ?? false;

  bool get _isEdit => widget.pet != null;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier ${pet!.name}' : 'Ajouter un animal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pet?.color.withValues(alpha: 0.35) ??
                        AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: pet != null
                      ? Text(pet.emoji, style: const TextStyle(fontSize: 60))
                      : const Icon(Icons.add_a_photo_rounded,
                          size: 40, color: AppColors.primary),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Ajouter une photo',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          const Text('Espèce',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              for (final (name, emoji) in _species)
                GestureDetector(
                  onTap: () => setState(() => _selectedSpecies = name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedSpecies == name
                          ? AppColors.primaryLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedSpecies == name
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LabeledField(
            label: 'Nom',
            hint: 'Ex : Rocky',
            icon: Icons.badge_outlined,
            initialValue: pet?.name,
          ),
          LabeledField(
            label: 'Race',
            hint: 'Ex : Golden Retriever',
            icon: Icons.pets_outlined,
            initialValue: pet?.breed,
          ),
          Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Date de naissance',
                  hint: 'JJ/MM/AAAA',
                  icon: Icons.event_outlined,
                  initialValue: pet?.birthDate,
                  readOnly: true,
                  onTap: () => showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: DateTime(2023, 4, 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Poids (kg)',
                  hint: 'Ex : 28,5',
                  icon: Icons.monitor_weight_outlined,
                  initialValue: pet?.weight.toString(),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const Text('Sexe',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 10),
          Row(
            children: [
              _SexOption(
                label: 'Mâle',
                icon: Icons.male_rounded,
                color: AppColors.vet,
                selected: _sex == 'Mâle',
                onTap: () => setState(() => _sex = 'Mâle'),
              ),
              const SizedBox(width: 12),
              _SexOption(
                label: 'Femelle',
                icon: Icons.female_rounded,
                color: AppColors.reminder,
                selected: _sex == 'Femelle',
                onTap: () => setState(() => _sex = 'Femelle'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LabeledField(
            label: 'Numéro de puce / tatouage',
            hint: '250 26 …',
            icon: Icons.memory_outlined,
            initialValue: pet?.chip,
          ),
          const LabeledField(
            label: 'Couleur / signes distinctifs',
            hint: 'Ex : pelage doré, tache blanche sur le torse',
            icon: Icons.palette_outlined,
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sterilized,
              onChanged: (v) => setState(() => _sterilized = v),
              title: const Text('Stérilisé(e)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.navy)),
              subtitle: const Text('L\'animal est-il stérilisé ?'),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnack(
                context,
                _isEdit
                    ? 'Modifications enregistrées'
                    : 'Animal ajouté avec succès 🎉',
              );
            },
            child: Text(_isEdit ? 'Enregistrer' : 'Ajouter l\'animal'),
          ),
        ],
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SexOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }
}
