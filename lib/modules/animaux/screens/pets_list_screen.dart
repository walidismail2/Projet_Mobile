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
import 'package:flutter_example/modules/sante/screens/add_health_record_screen.dart';
import 'package:flutter_example/modules/alimentation/screens/add_meal_screen.dart';

enum PetSortOption { name, age, weight }

class PetsListScreen extends StatefulWidget {
  const PetsListScreen({super.key});

  @override
  State<PetsListScreen> createState() => _PetsListScreenState();
}

class _PetsListScreenState extends State<PetsListScreen> {
  final _repo = PetRepository();
  late Future<List<Pet>> _future;

  String _searchQuery = '';
  String _selectedSpecies = 'Tous';
  PetSortOption _sortOption = PetSortOption.name;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
    _searchCtrl.dispose();
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

  List<Pet> _filterAndSort(List<Pet> source) {
    var list = source.where((p) {
      if (_selectedSpecies != 'Tous' && p.species != _selectedSpecies) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchBreed = p.breed.toLowerCase().contains(q);
        final matchSpecies = p.species.toLowerCase().contains(q);
        if (!matchName && !matchBreed && !matchSpecies) return false;
      }
      return true;
    }).toList();

    switch (_sortOption) {
      case PetSortOption.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case PetSortOption.age:
        list.sort((a, b) => a.birthDate.compareTo(b.birthDate));
        break;
      case PetSortOption.weight:
        list.sort((a, b) => a.weight.compareTo(b.weight));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes animaux'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<PetSortOption>(
            tooltip: 'Trier les animaux',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sortOption,
            onSelected: (opt) => setState(() => _sortOption = opt),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: PetSortOption.name,
                child: Text('Trier par nom (A-Z)'),
              ),
              PopupMenuItem(
                value: PetSortOption.weight,
                child: Text('Trier par poids'),
              ),
              PopupMenuItem(
                value: PetSortOption.age,
                child: Text('Trier par âge'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Boutique accessoires',
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Ajouter un animal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Pet>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPets = snap.data!;
          final filteredPets = _filterAndSort(allPets);

          // Unique species for dynamic filter chips
          final speciesCounts = <String, int>{'Tous': allPets.length};
          for (final p in allPets) {
            speciesCounts[p.species] = (speciesCounts[p.species] ?? 0) + 1;
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, race ou espèce...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Species Filter Pills
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Tous', speciesCounts['Tous'] ?? 0),
                      if (speciesCounts.containsKey('Chien'))
                        _buildFilterChip('Chien', speciesCounts['Chien']!, emoji: '🐶'),
                      if (speciesCounts.containsKey('Chat'))
                        _buildFilterChip('Chat', speciesCounts['Chat']!, emoji: '🐱'),
                      if (speciesCounts.containsKey('Lapin'))
                        _buildFilterChip('Lapin', speciesCounts['Lapin']!, emoji: '🐰'),
                      if (speciesCounts.containsKey('Oiseau'))
                        _buildFilterChip('Oiseau', speciesCounts['Oiseau']!, emoji: '🐦'),
                      for (final entry in speciesCounts.entries)
                        if (!['Tous', 'Chien', 'Chat', 'Lapin', 'Oiseau'].contains(entry.key))
                          _buildFilterChip(entry.key, entry.value, emoji: '🐾'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Dynamic Glance Metrics (when pets exist)
                if (allPets.isNotEmpty)
                  _buildGlanceBar(allPets),

                const SizedBox(height: 16),

                // Empty state if 0 pets in account
                if (allPets.isEmpty)
                  _buildNoPetsEmptyState()
                // Empty state if search returned 0
                else if (filteredPets.isEmpty)
                  _buildNoSearchResultState()
                // Pet Cards List
                else
                  for (final pet in filteredPets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDynamicPetCard(pet),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {String? emoji}) {
    final isSelected = _selectedSpecies == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          emoji != null ? '$emoji $label ($count)' : '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.navy,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedSpecies = label),
      ),
    );
  }

  Widget _buildGlanceBar(List<Pet> pets) {
    final totalWeight = pets.fold<double>(0.0, (acc, p) => acc + p.weight);
    final avgWeight = pets.isNotEmpty ? (totalWeight / pets.length).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _glanceItem(Icons.pets_rounded, '${pets.length}', 'Compagnon${pets.length > 1 ? 's' : ''}'),
          Container(width: 1, height: 28, color: AppColors.primary.withValues(alpha: 0.2)),
          _glanceItem(Icons.scale_rounded, '$avgWeight kg', 'Poids moyen'),
          Container(width: 1, height: 28, color: AppColors.primary.withValues(alpha: 0.2)),
          _glanceItem(Icons.health_and_safety_rounded, 'Actif', 'Suivi de santé'),
        ],
      ),
    );
  }

  Widget _glanceItem(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.navy,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicPetCard(Pet pet) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
        );
        if (mounted) setState(_reload);
      },
      child: Column(
        children: [
          // Main Info Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with species glow
                Stack(
                  children: [
                    PetAvatar(pet, size: 76, bordered: true),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          pet.sex == 'Mâle' ? Icons.male_rounded : Icons.female_rounded,
                          size: 14,
                          color: pet.sex == 'Mâle' ? AppColors.vet : AppColors.reminder,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Options',
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await _openForm(pet: pet);
                              } else if (v == 'delete' && pet.id != null) {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Supprimer ${pet.name} ?',
                                  message: 'Toutes les données associées seront supprimées.',
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
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: AppColors.navy),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.reminder),
                                    SizedBox(width: 8),
                                    Text('Supprimer', style: TextStyle(color: AppColors.reminder)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${pet.species} · ${pet.breed}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            pet.computedAge,
                            AppColors.primary,
                            icon: Icons.cake_outlined,
                          ),
                          StatusPill(
                            '${pet.weight} kg',
                            AppColors.health,
                            icon: Icons.monitor_weight_outlined,
                          ),
                          if (pet.sterilized)
                            const StatusPill(
                              'Stérilisé',
                              AppColors.vet,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Quick Actions strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                // Quick Add Vaccine / Health
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    if (pet.id == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddHealthRecordScreen(
                          type: HealthRecordType.vaccine,
                          initialPetId: pet.id,
                        ),
                      ),
                    );
                    if (mounted) setState(_reload);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.medical_services_outlined, size: 16, color: AppColors.health),
                        SizedBox(width: 4),
                        Text(
                          '+ Soin',
                          style: TextStyle(
                            color: AppColors.health,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Add Meal
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    if (pet.id == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMealScreen(
                          initialPetId: pet.id,
                        ),
                      ),
                    );
                    if (mounted) setState(_reload);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.restaurant_outlined, size: 16, color: AppColors.food),
                        SizedBox(width: 4),
                        Text(
                          '+ Repas',
                          style: TextStyle(
                            color: AppColors.food,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // View Details Link
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Fiche complète',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPetsEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.pets_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue dans PetCare !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ajoutez votre premier compagnon pour suivre sa santé, ses vaccins et son alimentation au jour le jour.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Ajouter un compagnon',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Aucun animal trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Essayez de modifier votre recherche ou de changer de filtre.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedSpecies = 'Tous';
                });
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }
}
