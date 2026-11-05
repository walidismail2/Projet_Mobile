import 'package:flutter/material.dart';

import '../../data/app_refresh.dart';
import '../../models/models.dart';
import '../../repositories/appointment_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../vets/vet_search_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _repo = AppointmentRepository();
  late Future<List<Appointment>> _future;
  bool _upcoming = true;

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
    _future = _repo.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VetSearchScreen()),
              );
              if (mounted) setState(_reload);
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final list = all
              .where((a) => _upcoming
                  ? a.status == AppointmentStatus.upcoming
                  : a.status != AppointmentStatus.upcoming)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppCard(
                color: AppColors.vet,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VetSearchScreen()),
                  );
                  if (mounted) setState(_reload);
                },
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Besoin d'un vétérinaire ?",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17)),
                          Text('Trouvez et réservez en quelques secondes',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.medical_services_outlined,
                        color: Colors.white, size: 40),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('À venir'),
                      selected: _upcoming,
                      onSelected: (_) => setState(() => _upcoming = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Historique'),
                      selected: !_upcoming,
                      onSelected: (_) => setState(() => _upcoming = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('Aucun rendez-vous',
                          style: TextStyle(color: AppColors.textSecondary))),
                ),
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(a.day,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: AppColors.primary)),
                                  Text(a.month,
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
                                  Text(a.reason,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(a.vet?.name ?? 'Vétérinaire'),
                                  Text('${a.time} · ${a.pet?.name ?? ''}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (a.status == AppointmentStatus.upcoming &&
                            a.id != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await _repo.updateStatus(
                                        a.id!, AppointmentStatus.cancelled);
                                    setState(_reload);
                                    if (context.mounted) {
                                      showSuccessSnack(
                                          context, 'Rendez-vous annulé');
                                    }
                                  },
                                  child: const Text('Annuler'),
                                ),
                              ),
                            ],
                          ),
                        ],
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
