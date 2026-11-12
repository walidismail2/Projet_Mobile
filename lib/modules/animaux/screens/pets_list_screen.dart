import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/animaux/screens/accessories_shop_screen.dart';
import 'package:flutter_example/modules/animaux/screens/pet_detail_screen.dart';
import 'package:flutter_example/modules/animaux/screens/pet_form_screen.dart';

class PetsListScreen extends StatefulWidget {
  const PetsListScreen({super.key});

  @override
  State<PetsListScreen> createState() => _PetsListScreenState();
}

class _PetsListScreenState extends State<PetsListScreen> {
  final _repo = PetRepository();
  late Future<List<Pet>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
    // Poids modifié depuis Alimentation (pesées), etc.
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(_reload);
  }

  void _reload() {
    _future = _repo.getByOwner(Session.instance.userId!);
  }

  Future<void> _openForm({Pet? pet}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
    );
    if (!mounted) return;
    setState(_reload);
    AppRefresh.instance.petsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes animaux'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Accessoires',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AccessoriesShopScreen(),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_pets',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter un animal',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<Pet>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text('${pets.length} compagnons',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              for (final pet in pets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppCard(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PetDetailScreen(pet: pet)),
                      );
                      if (mounted) setState(_reload);
                    },
                    child: Row(
                      children: [
                        PetAvatar(pet, size: 72),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text('${pet.species} · ${pet.breed}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                StatusPill(pet.computedAge, AppColors.primary),
                                StatusPill('${pet.weight} kg', AppColors.health),
                              ]),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _openForm(pet: pet);
                            } else if (pet.id != null) {
                              final ok = await showConfirmDialog(
                                context,
                                title: 'Supprimer ${pet.name} ?',
                                message: 'Action irréversible.',
                                confirmLabel: 'Supprimer',
                              );
                              if (ok && mounted) {
                                await LocalNotifications.instance.cancelForPet(pet.id!);
                                await _repo.delete(pet.id!);
                                setState(_reload);
                                AppRefresh.instance.petsChanged();
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
