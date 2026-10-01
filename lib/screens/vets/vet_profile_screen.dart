import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'booking_screen.dart';

class VetProfileScreen extends StatelessWidget {
  final Vet vet;

  const VetProfileScreen({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil du vétérinaire'),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border_rounded)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation', style: text.bodyMedium),
                  Text(vet.price, style: text.titleLarge),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookingScreen(vet: vet)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Prendre rendez-vous'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(child: VetAvatar(vet, size: 110)),
          const SizedBox(height: 14),
          Center(child: Text(vet.name, style: text.headlineMedium)),
          const SizedBox(height: 4),
          Center(
            child: Text('Vétérinaire ${vet.specialty.toLowerCase()}',
                style: text.bodyMedium),
          ),
          const SizedBox(height: 10),
          Center(
            child: vet.availableToday
                ? const StatusPill('Disponible aujourd\'hui', AppColors.health,
                    icon: Icons.bolt_rounded)
                : const StatusPill('Prochaine dispo : demain', AppColors.food,
                    icon: Icons.schedule_rounded),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(
                  icon: Icons.people_alt_rounded,
                  color: AppColors.vet,
                  value: '1 200+',
                  label: 'Patients'),
              const SizedBox(width: 12),
              _Stat(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.purple,
                  value: '${vet.experience} ans',
                  label: 'Expérience'),
              const SizedBox(width: 12),
              _Stat(
                  icon: Icons.star_rounded,
                  color: AppColors.food,
                  value: '${vet.rating}',
                  label: '${vet.reviews} avis'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader('À propos'),
          Text(
            '${vet.name} exerce à la ${vet.clinic} depuis ${vet.experience} ans. '
            'Passionné(e) par le bien-être animal, il/elle accompagne chiens, chats '
            'et NAC avec douceur et pédagogie.',
            style: text.bodyMedium!.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Services'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ServiceChip('Consultation'),
              _ServiceChip('Vaccination'),
              _ServiceChip('Chirurgie'),
              _ServiceChip('Radiologie'),
              _ServiceChip('Analyses'),
              _ServiceChip('Identification'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader('Adresse & horaires'),
          AppCard(
            child: Column(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on_rounded,
                        color: AppColors.vet, size: 40),
                  ),
                ),
                const SizedBox(height: 8),
                InfoRow(Icons.local_hospital_outlined, 'Clinique', vet.clinic),
                InfoRow(Icons.place_outlined, 'Adresse', vet.address),
                const InfoRow(Icons.schedule_rounded, 'Lun – Ven', '08:30 – 19:00'),
                const InfoRow(Icons.schedule_rounded, 'Samedi', '09:00 – 13:00'),
                const InfoRow(Icons.phone_outlined, 'Téléphone', '01 43 55 12 34'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader('Avis (${vet.reviews})', action: 'Voir tout'),
          const _Review(
            name: 'Julie M.',
            pet: '🐱 Mimi',
            text: 'Très à l\'écoute, ma chatte était détendue. Je recommande !',
            date: 'Il y a 2 jours',
          ),
          const _Review(
            name: 'Marc D.',
            pet: '🐶 Max',
            text: 'Explications claires et tarifs raisonnables. Super équipe.',
            date: 'Il y a 1 semaine',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            IconBadge(icon, color, size: 40),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;

  const _ServiceChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.vet.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.vet, fontWeight: FontWeight.w600)),
    );
  }
}

class _Review extends StatelessWidget {
  final String name;
  final String pet;
  final String text;
  final String date;

  const _Review({
    required this.name,
    required this.pet,
    required this.text,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(name[0],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      Text('$pet · $date',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(text,
                style: const TextStyle(color: AppColors.navy, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
