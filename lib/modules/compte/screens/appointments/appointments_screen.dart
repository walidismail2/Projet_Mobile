import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/appointment_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/screens/vets/vet_search_screen.dart';

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

  Future<void> _editAppointment(Appointment a) async {
    final reason = TextEditingController(text: a.reason);
    final time = TextEditingController(text: a.time);
    final date = TextEditingController(text: a.date);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le rendez-vous'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Motif'),
              ),
              TextField(
                controller: date,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              TextField(
                controller: time,
                decoration: const InputDecoration(labelText: 'Heure'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true || a.id == null) return;
    final updated = a.copyWith(
      reason: reason.text.trim(),
      date: date.text.trim(),
      time: time.text.trim(),
    );
    await _repo.update(updated);
    await LocalNotifications.instance.scheduleAppointment(updated);
    AppRefresh.instance.appointmentsChanged();
    setState(_reload);
    if (mounted) showSuccessSnack(context, 'Rendez-vous modifié');
  }

  Future<void> _deleteAppointment(Appointment a) async {
    if (a.id == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer ce rendez-vous ?',
      message: a.reason,
      confirmLabel: 'Supprimer',
    );
    if (!ok) return;
    await _repo.delete(a.id!);
    await LocalNotifications.instance
        .cancel(LocalNotifications.appointmentId(a.id!));
    AppRefresh.instance.appointmentsChanged();
    setState(_reload);
    if (mounted) showSuccessSnack(context, 'Rendez-vous supprimé');
  }

  Future<void> _setStatus(Appointment a, AppointmentStatus status) async {
    if (a.id == null) return;
    await _repo.updateStatus(a.id!, status);
    await LocalNotifications.instance
        .cancel(LocalNotifications.appointmentId(a.id!));
    AppRefresh.instance.appointmentsChanged();
    setState(_reload);
    if (!mounted) return;
    showSuccessSnack(
      context,
      status == AppointmentStatus.done
          ? 'Rendez-vous terminé'
          : 'Rendez-vous annulé',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VetSearchScreen()),
              );
              if (mounted) setState(_reload);
            },
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nouveau RDV',
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
                    MaterialPageRoute(
                        builder: (_) => const VetSearchScreen()),
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
                          Text('Créer un rendez-vous (Create)',
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                    child: Row(
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
                              const SizedBox(height: 4),
                              StatusPill(
                                a.status == AppointmentStatus.upcoming
                                    ? 'À venir'
                                    : a.status == AppointmentStatus.done
                                        ? 'Terminé'
                                        : 'Annulé',
                                a.status == AppointmentStatus.upcoming
                                    ? AppColors.vet
                                    : a.status == AppointmentStatus.done
                                        ? AppColors.health
                                        : AppColors.reminder,
                              ),
                            ],
                          ),
                        ),
                        if (a.id != null)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editAppointment(a);
                                case 'done':
                                  _setStatus(a, AppointmentStatus.done);
                                case 'cancel':
                                  _setStatus(a, AppointmentStatus.cancelled);
                                case 'delete':
                                  _deleteAppointment(a);
                              }
                            },
                            itemBuilder: (_) => [
                              if (a.status == AppointmentStatus.upcoming) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                const PopupMenuItem(
                                  value: 'done',
                                  child: Text('Terminé'),
                                ),
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Annuler'),
                                ),
                              ],
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
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
