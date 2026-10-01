import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../notifications/notifications_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../pets/pet_form_screen.dart';
import '../profile/profile_screen.dart';
import '../vets/vet_search_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = MockData.appointments.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text('SB',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour Sarah 👋', style: text.titleLarge),
                      Text('Mercredi 30 septembre', style: text.bodyMedium),
                    ],
                  ),
                ),
                RoundIconButton(
                  Icons.notifications_none_rounded,
                  badge: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader('Mes animaux',
                action: 'Voir tout', onAction: () => onNavigate(1)),
          ),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final pet in MockData.pets) ...[
                  _PetCard(pet: pet),
                  const SizedBox(width: 12),
                ],
                _AddPetCard(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader('Prochain rendez-vous',
                    action: 'Tous', onAction: () => onNavigate(3)),
                _NextAppointmentCard(appointment: next),
                const SizedBox(height: 24),
                const SectionHeader('Accès rapide'),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.vaccines_rounded,
                      label: 'Santé',
                      color: AppColors.health,
                      onTap: () => onNavigate(2),
                    ),
                    _QuickAction(
                      icon: Icons.local_hospital_rounded,
                      label: 'Vétérinaire',
                      color: AppColors.vet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VetSearchScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.restaurant_rounded,
                      label: 'Repas',
                      color: AppColors.food,
                      onTap: () => onNavigate(4),
                    ),
                    _QuickAction(
                      icon: Icons.notifications_active_rounded,
                      label: 'Rappels',
                      color: AppColors.reminder,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader('Aujourd\'hui'),
                const _TodayReminder(
                  icon: Icons.restaurant_rounded,
                  color: AppColors.food,
                  title: 'Friandise de Rocky',
                  subtitle: 'Bâtonnet dentaire · 1 unité',
                  time: '16:00',
                ),
                const _TodayReminder(
                  icon: Icons.medication_rounded,
                  color: AppColors.purple,
                  title: 'Antibiotique de Luna',
                  subtitle: '1 comprimé · jour 4/10',
                  time: '18:00',
                ),
                const _TodayReminder(
                  icon: Icons.restaurant_rounded,
                  color: AppColors.food,
                  title: 'Dîner de Rocky',
                  subtitle: 'Croquettes · 130 g',
                  time: '19:30',
                ),
                const SizedBox(height: 12),
                const _HealthTipCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
      ),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pet.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(pet.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const Spacer(),
            Text(pet.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.navy)),
            Text('${pet.age} · ${pet.weight} kg',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetFormScreen()),
      ),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            SizedBox(height: 10),
            Text('Ajouter',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _NextAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B8CFF), Color(0xFF3D63E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(appointment.vet.initials,
                    style: const TextStyle(
                        color: AppColors.vet,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.vet.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.reason} · ${appointment.pet.name}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(appointment.pet.emoji,
                  style: const TextStyle(fontSize: 30)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(appointment.date,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(appointment.time,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}

class _TodayReminder extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _TodayReminder({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconBadge(icon, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(time,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.navy)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.health.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 34)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conseil du jour',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.health)),
                SizedBox(height: 4),
                Text(
                  'Pensez à laisser de l\'eau fraîche à disposition de vos animaux toute la journée.',
                  style: TextStyle(color: AppColors.navy, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
