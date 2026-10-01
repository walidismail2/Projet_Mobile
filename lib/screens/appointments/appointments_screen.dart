import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../vets/booking_screen.dart';
import '../vets/vet_profile_screen.dart';
import '../vets/vet_search_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = MockData.appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .toList();
    final past = MockData.appointments
        .where((a) => a.status != AppointmentStatus.upcoming)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Rendez-vous',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    RoundIconButton(
                      Icons.search_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VetSearchScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _FindVetBanner(),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  tabs: [
                    Tab(text: 'À venir (${upcoming.length})'),
                    Tab(text: 'Historique (${past.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        for (final a in upcoming) _UpcomingCard(appointment: a),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        for (final a in past) _PastCard(appointment: a),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindVetBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B8CFF), Color(0xFF3D63E0)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Besoin d\'un vétérinaire ?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Trouvez et réservez en quelques secondes',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13)),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.vet,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VetSearchScreen()),
                  ),
                  child: const Text('Prendre RDV'),
                ),
              ],
            ),
          ),
          const Text('🩺', style: TextStyle(fontSize: 64)),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final Appointment appointment;
  final Color color;

  const _DateBox({required this.appointment, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(appointment.day,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(appointment.month,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Appointment appointment;

  const _UpcomingCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VetProfileScreen(vet: a.vet)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _DateBox(appointment: a, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.reason,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(a.vet.name,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.textSecondary),
                          Text(' ${a.time}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy)),
                          const SizedBox(width: 12),
                          Text('${a.pet.emoji} ${a.pet.name}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.reminder,
                    ),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Annuler le rendez-vous ?',
                        message:
                            '${a.reason} avec ${a.vet.name} le ${a.date} à ${a.time}.',
                        confirmLabel: 'Annuler le RDV',
                        icon: Icons.event_busy_rounded,
                      );
                      if (ok && context.mounted) {
                        showSuccessSnack(context, 'Rendez-vous annulé');
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingScreen(vet: a.vet, existing: a),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: const Text('Modifier'),
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

class _PastCard extends StatelessWidget {
  final Appointment appointment;

  const _PastCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final cancelled = a.status == AppointmentStatus.cancelled;
    final color = cancelled ? AppColors.reminder : AppColors.health;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            _DateBox(appointment: a, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.reason,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${a.vet.name} · ${a.pet.emoji} ${a.pet.name}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  StatusPill(
                    cancelled ? 'Annulé' : 'Terminé',
                    color,
                    icon: cancelled
                        ? Icons.cancel_rounded
                        : Icons.check_circle_rounded,
                  ),
                ],
              ),
            ),
            if (!cancelled)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingScreen(vet: a.vet)),
                ),
                child: const Text('Reprendre'),
              ),
          ],
        ),
      ),
    );
  }
}
