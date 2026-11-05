import 'package:flutter/material.dart';

import '../../data/app_refresh.dart';
import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/health_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../repositories/reminder_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../notifications/notifications_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../pets/pet_form_screen.dart';
import '../profile/profile_screen.dart';
import '../vets/vet_search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_Data> _future;

  @override
  void initState() {
    super.initState();
    _reload();
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(_reload);
  }

  void _reload() {
    _future = () async {
      final ownerId = Session.instance.userId;
      if (ownerId == null) {
        return _Data(pets: const [], next: null);
      }
      final pets = await PetRepository().getByOwner(ownerId);
      final appts = await AppointmentRepository().getAll();
      final next = appts
          .where((a) => a.status == AppointmentStatus.upcoming)
          .toList();
      final health = HealthRepository();
      var watch = 0;
      var treatments = 0;
      for (final pet in pets) {
        final id = pet.id;
        if (id == null) continue;
        final summary = await health.summaryForPet(id);
        watch += summary.vaccinesLate;
        treatments += summary.treatmentsActive;
      }
      final unread = await ReminderRepository().unreadCount();
      return _Data(
        pets: pets,
        next: next.isEmpty ? null : next.first,
        vaccinesToWatch: watch,
        activeTreatments: treatments,
        unread: unread,
      );
    }();
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.currentUser;
    final first = user?.name.split(' ').first ?? 'ami';
    final initials = () {
      final n = user?.name ?? '?';
      final p = n.trim().split(RegExp(r'\s+'));
      if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
      return n.isEmpty ? '?' : n[0].toUpperCase();
    }();

    return SafeArea(
      child: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                        if (mounted) setState(_reload);
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(initials,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Bonjour $first 👋',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    RoundIconButton(
                      data.unread > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                      badge: data.unread > 0,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                        if (mounted) setState(_reload);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader('Mes animaux',
                    action: 'Voir tout',
                    onAction: () => widget.onNavigate(1)),
              ),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final pet in data.pets) ...[
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PetDetailScreen(pet: pet)),
                        ),
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              PetAvatar(pet, size: 56),
                              const SizedBox(height: 8),
                              Text(pet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(pet.species,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PetFormScreen()),
                        );
                        if (!mounted) return;
                        setState(_reload);
                        AppRefresh.instance.petsChanged();
                      },
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.primary),
                            Text('Ajouter',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader('Prochain rendez-vous',
                        action: 'Tous',
                        onAction: () => widget.onNavigate(3)),
                    if (data.next == null)
                      const AppCard(
                          child: Text('Aucun rendez-vous à venir'))
                    else
                      AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(data.next!.day,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: AppColors.primary)),
                                  Text(data.next!.month,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.next!.reason,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(data.next!.vet?.name ??
                                      'Vétérinaire'),
                                  Text(
                                      '${data.next!.time} · ${data.next!.pet?.name ?? ''}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _HealthBanner(
                      vaccinesToWatch: data.vaccinesToWatch,
                      activeTreatments: data.activeTreatments,
                      hasPets: data.pets.isNotEmpty,
                      onTap: () => widget.onNavigate(2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            onTap: () => widget.onNavigate(2),
                            child: const Column(
                              children: [
                                IconBadge(Icons.vaccines_rounded,
                                    AppColors.health),
                                SizedBox(height: 8),
                                Text('Santé',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VetSearchScreen()),
                            ),
                            child: const Column(
                              children: [
                                IconBadge(
                                    Icons.search_rounded, AppColors.vet),
                                SizedBox(height: 8),
                                Text('Vétos',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            onTap: () => widget.onNavigate(4),
                            child: const Column(
                              children: [
                                IconBadge(Icons.restaurant_rounded,
                                    AppColors.food),
                                SizedBox(height: 8),
                                Text('Repas',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Data {
  final List<Pet> pets;
  final Appointment? next;
  final int vaccinesToWatch;
  final int activeTreatments;
  final int unread;

  _Data({
    required this.pets,
    required this.next,
    this.vaccinesToWatch = 0,
    this.activeTreatments = 0,
    this.unread = 0,
  });
}

class _HealthBanner extends StatelessWidget {
  final int vaccinesToWatch;
  final int activeTreatments;
  final bool hasPets;
  final VoidCallback onTap;

  const _HealthBanner({
    required this.vaccinesToWatch,
    required this.activeTreatments,
    required this.hasPets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final alert = vaccinesToWatch > 0;
    final color = alert ? AppColors.reminder : AppColors.health;
    final title = !hasPets
        ? 'Ajoutez un animal'
        : alert
            ? '$vaccinesToWatch vaccin${vaccinesToWatch > 1 ? 's' : ''} à surveiller'
            : 'Vaccins à jour';
    final subtitle = !hasPets
        ? 'Le suivi santé commence ici'
        : activeTreatments == 0
            ? 'Aucun traitement en cours'
            : '$activeTreatments traitement${activeTreatments > 1 ? 's' : ''} en cours';

    return AppCard(
      onTap: onTap,
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          IconBadge(
            alert ? Icons.warning_amber_rounded : Icons.favorite_rounded,
            color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
