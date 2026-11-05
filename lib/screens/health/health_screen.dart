import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../data/app_refresh.dart';
import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/health_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'add_health_record_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _petsRepo = PetRepository();
  final _healthRepo = HealthRepository();
  List<Pet> _pets = [];
  int _pet = 0;
  List<Vaccine> _vaccines = [];
  List<Treatment> _treatments = [];
  List<MedicalEvent> _events = [];
  List<MedicalDocument> _docs = [];
  bool _loading = true;

  int get _vaccinesOk =>
      _vaccines.where((v) => v.status == HealthStatus.upToDate).length;
  int get _vaccinesAlert => _vaccines
      .where((v) =>
          v.status == HealthStatus.late || v.status == HealthStatus.soon)
      .length;
  int get _treatmentsActive =>
      _treatments.where((t) => !t.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _load();
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return;
    final pets = await _petsRepo.getByOwner(ownerId);
    if (!mounted) return;
    setState(() {
      _pets = pets;
      if (_pet >= _pets.length) _pet = 0;
      _loading = false;
    });
    await _loadHealth();
  }

  Future<void> _loadHealth() async {
    if (_pets.isEmpty) {
      if (mounted) {
        setState(() {
          _vaccines = [];
          _treatments = [];
          _events = [];
          _docs = [];
        });
      }
      return;
    }
    final id = _pets[_pet].id!;
    final v = await _healthRepo.getVaccines(id);
    final t = await _healthRepo.getTreatments(id);
    final e = await _healthRepo.getEvents(id);
    final d = await _healthRepo.getDocuments(id);
    if (mounted) {
      setState(() {
        _vaccines = v;
        _treatments = t;
        _events = e;
        _docs = d;
      });
    }
  }

  Future<void> _openAdd(HealthRecordType type) async {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez d’abord un animal')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthRecordScreen(
          type: type,
          initialPetId: _pets[_pet].id,
        ),
      ),
    );
    await _loadHealth();
  }

  Color _statusColor(HealthStatus s) => switch (s) {
        HealthStatus.upToDate => AppColors.health,
        HealthStatus.soon => AppColors.food,
        HealthStatus.late => AppColors.reminder,
      };

  Future<void> _confirmDelete(String label, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer « $label » ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await action();
      await _loadHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_health',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in HealthRecordType.values)
                      ListTile(
                        leading: IconBadge(type.icon, type.color),
                        title: Text(type.label),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openAdd(type);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Santé',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              if (_pets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ajoutez un animal pour suivre vaccins, traitements et documents.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else ...[
                PetSelector(
                  pets: _pets,
                  selected: _pet,
                  onChanged: (i) async {
                    setState(() => _pet = i);
                    await _loadHealth();
                  },
                ),
                _SummaryBar(
                  vaccinesOk: _vaccinesOk,
                  vaccinesAlert: _vaccinesAlert,
                  treatmentsActive: _treatmentsActive,
                  totalVaccines: _vaccines.length,
                ),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Vaccins'),
                    Tab(text: 'Traitements'),
                    Tab(text: 'Historique'),
                    Tab(text: 'Documents'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _list(
                        empty: 'Aucun vaccin enregistré',
                        children: _vaccines.map(_vaccineCard),
                      ),
                      _list(
                        empty: 'Aucun traitement en cours',
                        children: _treatments.map(_treatmentCard),
                      ),
                      _list(
                        empty: 'Aucune consultation',
                        children: _events.map(_eventCard),
                      ),
                      _list(
                        empty: 'Aucun document',
                        children: _docs.map(_docCard),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vaccineCard(Vaccine v) {
    final days = () {
      final next = parseFrDate(v.nextDate);
      if (next == null) return null;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return next.difference(today).inDays;
    }();
    final detail = days == null
        ? 'Rappel : ${v.nextDate}'
        : days < 0
            ? 'En retard de ${-days} j'
            : days == 0
                ? 'Rappel aujourd’hui'
                : 'Rappel dans $days j';

    return AppCard(
      child: ListTile(
        leading: const IconBadge(Icons.vaccines, AppColors.health),
        title: Text(v.name),
        subtitle: Text(
          '${v.date} → ${v.nextDate}\n${v.vet}\n$detail',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(v.status.label, _statusColor(v.status)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(
                v.name,
                () => _healthRepo.deleteVaccine(v.id!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _treatmentCard(Treatment t) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(t.icon, AppColors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${t.dosage} · ${t.frequency}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                StatusPill(
                  t.isCompleted ? 'Terminé' : 'Jour ${t.currentDay}/${t.totalDays}',
                  t.isCompleted ? AppColors.health : AppColors.purple,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(
                    t.name,
                    () => _healthRepo.deleteTreatment(t.id!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: t.progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: t.isCompleted ? AppColors.health : AppColors.purple,
              ),
            ),
            if (!t.isCompleted) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await _healthRepo.advanceTreatmentDay(t);
                    await _loadHealth();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Jour pris'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventCard(MedicalEvent e) {
    return AppCard(
      child: ListTile(
        leading: IconBadge(e.icon, e.color),
        title: Text(e.title),
        subtitle: Text(
          e.description.trim().isEmpty
              ? e.date
              : '${e.date}\n${e.description}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _confirmDelete(
            e.title,
            () => _healthRepo.deleteEvent(e.id!),
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(MedicalDocument d) async {
    final path = d.filePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier introuvable')),
      );
      return;
    }
    if (!d.isPdf) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(d.name, overflow: TextOverflow.ellipsis),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      OpenFilex.open(path);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: InteractiveViewer(
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final result = await OpenFilex.open(path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Widget _docCard(MedicalDocument d) {
    final hasFile =
        d.filePath != null && File(d.filePath!).existsSync();
    return AppCard(
      onTap: hasFile ? () => _openDocument(d) : null,
      child: ListTile(
        leading: !d.isPdf && hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(d.filePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            : IconBadge(
                d.isPdf ? Icons.picture_as_pdf : Icons.image,
                AppColors.food,
              ),
        title: Text(d.name),
        subtitle: Text(
          '${d.date} · ${d.isPdf ? 'PDF' : 'Image'}'
          '${d.size == '—' || d.size.isEmpty ? '' : ' · ${d.size}'}'
          '${hasFile ? '' : ' · fichier manquant'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFile)
              IconButton(
                tooltip: 'Ouvrir',
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: () => _openDocument(d),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(
                d.name,
                () => _healthRepo.deleteDocument(d.id!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list({
    required String empty,
    required Iterable<Widget> children,
  }) {
    final items = children.toList();
    if (items.isEmpty) {
      return Center(
        child: Text(empty,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final c in items) ...[c, const SizedBox(height: 10)],
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int vaccinesOk;
  final int vaccinesAlert;
  final int treatmentsActive;
  final int totalVaccines;

  const _SummaryBar({
    required this.vaccinesOk,
    required this.vaccinesAlert,
    required this.treatmentsActive,
    required this.totalVaccines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _chip(
              Icons.vaccines_rounded,
              AppColors.health,
              totalVaccines == 0
                  ? 'Aucun vaccin'
                  : '$vaccinesOk / $totalVaccines à jour',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _chip(
              Icons.warning_amber_rounded,
              vaccinesAlert > 0 ? AppColors.reminder : AppColors.health,
              vaccinesAlert == 0
                  ? 'Rien en retard'
                  : '$vaccinesAlert à surveiller',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _chip(
              Icons.medication_rounded,
              AppColors.purple,
              treatmentsActive == 0
                  ? 'Pas de traitement'
                  : '$treatmentsActive en cours',
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
