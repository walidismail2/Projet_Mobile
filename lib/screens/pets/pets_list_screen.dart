import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class PetsListScreen extends StatelessWidget {
  const PetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes animaux'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PetFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter un animal',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un animal…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text('${MockData.pets.length} compagnons',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final pet in MockData.pets) _PetTile(pet: pet),
        ],
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  final Pet pet;

  const _PetTile({required this.pet});

  @override
  Widget build(BuildContext context) {
    final isMale = pet.sex == 'Mâle';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
        ),
        child: Row(
          children: [
            PetAvatar(pet, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(pet.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 6),
                      Icon(
                        isMale ? Icons.male_rounded : Icons.female_rounded,
                        size: 20,
                        color: isMale ? AppColors.vet : AppColors.reminder,
                      ),
                    ],
                  ),
                  Text('${pet.species} · ${pet.breed}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusPill(pet.age, AppColors.primary,
                          icon: Icons.cake_rounded),
                      StatusPill('${pet.weight} kg', AppColors.health,
                          icon: Icons.monitor_weight_rounded),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
                  );
                } else {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Supprimer ${pet.name} ?',
                    message:
                        'Toutes ses données (santé, repas, rendez-vous) seront définitivement supprimées.',
                    confirmLabel: 'Supprimer',
                  );
                  if (ok && context.mounted) {
                    showSuccessSnack(context, '${pet.name} a été supprimé');
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Modifier'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading:
                        Icon(Icons.delete_rounded, color: AppColors.reminder),
                    title: Text('Supprimer',
                        style: TextStyle(color: AppColors.reminder)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
