import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/sante/repositories/health_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/modules/animaux/services/pet_ideal_service.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/animaux/screens/pet_form_screen.dart';

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
                      PetAvatar(pet, size: 130, bordered: true),
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
                        value: pet.computedAge,
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
                const SectionHeader('Idéal race & âge'),
                _IdealCareCard(pet: pet),
                const SizedBox(height: 24),
                const SectionHeader('Évolution du poids'),
                _WeightChart(pet: pet),
                const SizedBox(height: 24),
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
                SizedBox(height: text.bodyMedium!.fontSize),
              ],
            ),
          ),
        ],
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
              const SizedBox(height: 12),
              const Text(
                'Conseils',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
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
                        child: Text(tip,
                            style: const TextStyle(
                                height: 1.35,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Source',
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
