import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/sante/repositories/health_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/modules/animaux/services/pet_ideal_service.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/animaux/screens/pet_form_screen.dart';
import 'package:flutter_example/modules/sante/screens/add_health_record_screen.dart';
import 'package:flutter_example/modules/alimentation/screens/add_meal_screen.dart';
import 'package:flutter_example/modules/compte/screens/vets/vet_search_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Pet _currentPet;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshPet() async {
    if (_currentPet.id == null) return;
    final updated = await PetRepository().getById(_currentPet.id!);
    if (updated != null && mounted) {
      setState(() => _currentPet = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = _currentPet;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 290,
              pinned: true,
              backgroundColor: pet.color,
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: RoundIconButton(
                  Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              actions: [
                RoundIconButton(
                  Icons.edit_rounded,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetFormScreen(pet: pet),
                      ),
                    );
                    _refreshPet();
                  },
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        pet.color,
                        pet.color.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Hero(
                          tag: 'pet_avatar_${pet.id}',
                          child: PetAvatar(pet, size: 124, bordered: true),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${pet.species} · ${pet.breed}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              pet.sex == 'Mâle'
                                  ? Icons.male_rounded
                                  : Icons.female_rounded,
                              size: 18,
                              color: pet.sex == 'Mâle'
                                  ? AppColors.vet
                                  : AppColors.reminder,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.dashboard_outlined, size: 20),
                      text: 'Aperçu',
                    ),
                    Tab(
                      icon: Icon(Icons.monitor_weight_outlined, size: 20),
                      text: 'Poids & Santé',
                    ),
                    Tab(
                      icon: Icon(Icons.auto_awesome_outlined, size: 20),
                      text: 'Idéal & Conseils',
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(pet),
            _buildWeightAndHealthTab(pet),
            _buildIdealCareTab(pet),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Pet pet) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Stat Boxes
        Row(
          children: [
            _StatBox(
              label: 'Âge',
              value: pet.computedAge,
              icon: Icons.cake_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _StatBox(
              label: 'Poids',
              value: '${pet.weight} kg',
              icon: Icons.monitor_weight_rounded,
              color: AppColors.health,
            ),
            const SizedBox(width: 12),
            _StatBox(
              label: 'Sexe',
              value: pet.sex,
              icon: pet.sex == 'Mâle'
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              color: AppColors.vet,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Dynamic Quick Actions Hub
        const SectionHeader('Actions rapides'),
        Row(
          children: [
            _QuickActionTile(
              icon: Icons.medical_services_outlined,
              label: '+ Soin',
              color: AppColors.health,
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
                _refreshPet();
              },
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.restaurant_outlined,
              label: '+ Repas',
              color: AppColors.food,
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
                _refreshPet();
              },
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.local_hospital_outlined,
              label: 'Véto',
              color: AppColors.vet,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VetSearchScreen()),
              ),
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.edit_outlined,
              label: 'Éditer',
              color: AppColors.primary,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PetFormScreen(pet: pet),
                  ),
                );
                _refreshPet();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Life Stage Tracker
        const SectionHeader('Cycle de vie'),
        _LifeStageProgress(pet: pet),
        const SizedBox(height: 24),

        // Detailed Identité Card
        const SectionHeader('Informations d\'identité'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              InfoRow(Icons.category_rounded, 'Espèce', pet.species),
              const Divider(height: 1),
              InfoRow(Icons.pets_rounded, 'Race', pet.breed),
              const Divider(height: 1),
              InfoRow(Icons.event_rounded, 'Date de naissance', pet.birthDate),
              const Divider(height: 1),
              // Chip row with copy shortcut
              InkWell(
                onTap: () {
                  if (pet.chip.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: pet.chip));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('N° de puce ${pet.chip} copié !'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.memory_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        'N° de puce',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        pet.chip.isEmpty ? 'Non renseigné' : pet.chip,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pet.chip.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              InfoRow(Icons.health_and_safety_rounded, 'Stérilisé',
                  pet.sterilized ? 'Oui' : 'Non'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Delete Pet button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.reminder,
            side: const BorderSide(color: AppColors.reminder),
          ),
          onPressed: () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Supprimer ${pet.name} ?',
              message:
                  'Cette action est irréversible. Toutes les données de ${pet.name} seront perdues.',
              confirmLabel: 'Supprimer',
            );
            if (ok && context.mounted && pet.id != null) {
              await LocalNotifications.instance.cancelForPet(pet.id!);
              await PetRepository().delete(pet.id!);
              if (context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text('Supprimer ${pet.name}'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeightAndHealthTab(Pet pet) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Dynamic Weight Gauge based on breed ideals
        const SectionHeader('Jauge de corpulence'),
        _WeightGaugeCard(pet: pet),
        const SizedBox(height: 24),

        // Interactive Weight Chart
        const SectionHeader('Évolution du poids'),
        _InteractiveWeightChart(pet: pet),
        const SizedBox(height: 24),

        // Live Health Summary
        const SectionHeader('Résumé santé'),
        if (pet.id != null)
          FutureBuilder(
            future: HealthRepository().summaryForPet(pet.id!),
            builder: (context, snap) {
              final s = snap.data;
              final vaccines = s == null
                  ? '…'
                  : '${s.vaccinesOk + s.vaccinesLate} vaccin${(s.vaccinesOk + s.vaccinesLate) > 1 ? 's' : ''}';
              final vaccinesSub = s == null
                  ? '…'
                  : s.vaccinesLate == 0
                      ? 'Tous à jour'
                      : '${s.vaccinesLate} à surveiller';
              final treatments = s == null
                  ? '…'
                  : '${s.treatmentsActive} traitement${s.treatmentsActive > 1 ? 's' : ''}';
              final treatmentsSub = s == null
                  ? '…'
                  : s.treatmentsActive == 0
                      ? 'Aucun en cours'
                      : 'En cours';
              return Row(
                children: [
                  _SummaryTile(
                    icon: Icons.vaccines_rounded,
                    color: AppColors.health,
                    title: vaccines,
                    subtitle: vaccinesSub,
                  ),
                  const SizedBox(width: 12),
                  _SummaryTile(
                    icon: Icons.medication_rounded,
                    color: AppColors.primary,
                    title: treatments,
                    subtitle: treatmentsSub,
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildIdealCareTab(Pet pet) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader('Recommandations adaptées'),
        _IdealCareCard(pet: pet),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _LifeStageProgress extends StatelessWidget {
  final Pet pet;

  const _LifeStageProgress({required this.pet});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetIdealProfile>(
      future: PetIdealService().forPet(pet),
      builder: (context, snap) {
        final stage = snap.data?.stage ?? PetLifeStage.adult;
        final stages = [
          (PetLifeStage.puppy, pet.species == 'Chat' ? 'Chaton' : (pet.species == 'Chien' ? 'Chiot' : 'Jeune')),
          (PetLifeStage.adult, 'Adulte'),
          (PetLifeStage.senior, 'Senior'),
        ];

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final s in stages)
                    _stageBadge(
                      label: s.$2,
                      isActive: s.$1 == stage,
                      isCompleted: _stageRank(stage) > _stageRank(s.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_stageRank(stage) + 1) / 3.0,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _stageRank(PetLifeStage stage) => switch (stage) {
        PetLifeStage.puppy => 0,
        PetLifeStage.adult => 1,
        PetLifeStage.senior => 2,
      };

  Widget _stageBadge({
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isActive
        ? AppColors.primary
        : (isCompleted ? AppColors.health : AppColors.textSecondary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : (isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WeightGaugeCard extends StatelessWidget {
  final Pet pet;

  const _WeightGaugeCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetIdealProfile>(
      future: PetIdealService().forPet(pet),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final ideal = snap.data!;
        final minW = ideal.weightMinKg;
        final maxW = ideal.weightMaxKg;

        String verdictText;
        Color verdictColor;
        double indicatorPos = 0.5; // 0 = low, 0.5 = ideal, 1.0 = high

        if (minW != null && maxW != null) {
          if (pet.weight < minW) {
            verdictText = 'Léger sous-poids (idéal: ${ideal.weightRangeLabel})';
            verdictColor = AppColors.vet;
            indicatorPos = 0.15;
          } else if (pet.weight > maxW) {
            verdictText = 'Léger surpoids (idéal: ${ideal.weightRangeLabel})';
            verdictColor = AppColors.food;
            indicatorPos = 0.85;
          } else {
            verdictText = 'Poids idéal ! (plage: ${ideal.weightRangeLabel})';
            verdictColor = AppColors.health;
            indicatorPos = 0.5;
          }
        } else {
          verdictText = ideal.weightVerdict;
          verdictColor = AppColors.health;
        }

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_weight_rounded, color: verdictColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${pet.weight} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  StatusPill(verdictText, verdictColor),
                ],
              ),
              const SizedBox(height: 16),

              // Visual gauge track
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCE6FC),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 10,
                          color: const Color(0xFFD1F4E4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE0D4),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment(-1.0 + (indicatorPos * 2.0), 0),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: verdictColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: verdictColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Sous-poids', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('Zone Idéale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.health)),
                  Text('Surpoids', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InteractiveWeightChart extends StatefulWidget {
  final Pet pet;

  const _InteractiveWeightChart({required this.pet});

  @override
  State<_InteractiveWeightChart> createState() => _InteractiveWeightChartState();
}

class _InteractiveWeightChartState extends State<_InteractiveWeightChart> {
  int _selectedDurationMonths = 6;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final months = _selectedDurationMonths == 3
        ? ['Juil', 'Août', 'Sept']
        : ['Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept'];
    final ratios = _selectedDurationMonths == 3
        ? [0.95, 0.97, 1.0]
        : [0.88, 0.90, 0.93, 0.95, 0.97, 1.0];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Text('${pet.weight} kg',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              const StatusPill('+0,4 kg', AppColors.health,
                  icon: Icons.trending_up_rounded),
              const Spacer(),
              // Duration selector chips
              GestureDetector(
                onTap: () => setState(() => _selectedDurationMonths = 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedDurationMonths == 3
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3M',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedDurationMonths == 3 ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _selectedDurationMonths = 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedDurationMonths == 6
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '6M',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedDurationMonths == 6 ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _hoveredIndex = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_hoveredIndex == i)
                            Text(
                              '${(pet.weight * ratios[i]).toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          Container(
                            height: 85 * ratios[i],
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: i == months.length - 1 || _hoveredIndex == i
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            months[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _hoveredIndex == i ? FontWeight.w800 : FontWeight.w500,
                              color: _hoveredIndex == i ? AppColors.navy : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdealCareCard extends StatelessWidget {
  final Pet pet;

  const _IdealCareCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetIdealProfile>(
      future: PetIdealService().forPet(pet),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final ideal = snap.data;
        if (ideal == null) {
          return const AppCard(
            child: Text('Impossible de calculer les idéaux pour cet animal.'),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phase : ${ideal.stageLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ideal.summary,
                style: const TextStyle(height: 1.4, color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              if (ideal.weightRangeLabel != null)
                InfoRow(Icons.monitor_weight_outlined, 'Poids idéal',
                    ideal.weightRangeLabel!),
              if (ideal.lifeSpanLabel != null)
                InfoRow(Icons.hourglass_bottom_rounded, 'Espérance de vie',
                    ideal.lifeSpanLabel!),
              if (ideal.exerciseMinutes != null)
                InfoRow(Icons.directions_run_rounded, 'Exercice type',
                    '${ideal.exerciseMinutes} min/jour'),
              const SizedBox(height: 8),
              Text(
                ideal.weightVerdict,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ideal.weightVerdict.contains('idéale')
                      ? AppColors.health
                      : AppColors.food,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Conseils personnalisés',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              for (final tip in ideal.tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Source de référence',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              if (ideal.sourceUrl != null)
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(ideal.sourceUrl!);
                    try {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (_) {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    }
                  },
                  child: Text(
                    ideal.sourceUrl!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Text(
                  ideal.source,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.navy,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBadge(icon, color, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
