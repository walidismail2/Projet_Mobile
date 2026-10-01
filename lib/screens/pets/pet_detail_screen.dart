import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: pet.color,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: RoundIconButton(Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context)),
            ),
            actions: [
              RoundIconButton(
                Icons.edit_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pet.color, pet.color.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 130,
                        height: 130,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Text(pet.emoji,
                            style: const TextStyle(fontSize: 70)),
                      ),
                      const SizedBox(height: 12),
                      Text(pet.name,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy)),
                      Text('${pet.species} · ${pet.breed}',
                          style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    _StatBox(
                        label: 'Âge',
                        value: pet.age,
                        icon: Icons.cake_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    _StatBox(
                        label: 'Poids',
                        value: '${pet.weight} kg',
                        icon: Icons.monitor_weight_rounded,
                        color: AppColors.health),
                    const SizedBox(width: 12),
                    _StatBox(
                        label: 'Sexe',
                        value: pet.sex,
                        icon: pet.sex == 'Mâle'
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        color: AppColors.vet),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader('Informations'),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      InfoRow(Icons.category_rounded, 'Espèce', pet.species),
                      const Divider(height: 1),
                      InfoRow(Icons.pets_rounded, 'Race', pet.breed),
                      const Divider(height: 1),
                      InfoRow(Icons.event_rounded, 'Date de naissance',
                          pet.birthDate),
                      const Divider(height: 1),
                      InfoRow(Icons.memory_rounded, 'N° de puce', pet.chip),
                      const Divider(height: 1),
                      InfoRow(Icons.health_and_safety_rounded, 'Stérilisé',
                          pet.sterilized ? 'Oui' : 'Non'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader('Évolution du poids'),
                _WeightChart(pet: pet),
                const SizedBox(height: 24),
                const SectionHeader('Résumé'),
                const Row(
                  children: [
                    _SummaryTile(
                        icon: Icons.vaccines_rounded,
                        color: AppColors.health,
                        title: '4 vaccins',
                        subtitle: '1 en retard'),
                    SizedBox(width: 12),
                    _SummaryTile(
                        icon: Icons.medication_rounded,
                        color: AppColors.purple,
                        title: '3 traitements',
                        subtitle: '1 en cours'),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    _SummaryTile(
                        icon: Icons.event_available_rounded,
                        color: AppColors.vet,
                        title: 'RDV le 02/10',
                        subtitle: 'Dr. Martin'),
                    SizedBox(width: 12),
                    _SummaryTile(
                        icon: Icons.restaurant_rounded,
                        color: AppColors.food,
                        title: '4 repas / jour',
                        subtitle: '1 120 kcal'),
                  ],
                ),
                const SizedBox(height: 28),
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
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text('Supprimer ${pet.name}'),
                ),
                SizedBox(height: text.bodyMedium!.fontSize),
              ],
            ),
          ),
        ],
      ),
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
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.navy)),
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final Pet pet;

  const _WeightChart({required this.pet});

  @override
  Widget build(BuildContext context) {
    const months = ['Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept'];
    const ratios = [0.88, 0.9, 0.93, 0.95, 0.97, 1.0];
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
              Text('6 derniers mois',
                  style: Theme.of(context).textTheme.bodyMedium),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 90 * ratios[i],
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: i == months.length - 1
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(months[i],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
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
