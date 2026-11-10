import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/sante/repositories/health_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/modules/sante/services/health_tip_service.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/modules/sante/services/vaccine_suggestion_service.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/sante/screens/add_health_record_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _petsRepo = PetRepository();
  final _healthRepo = HealthRepository();
  final _tipService = HealthTipService();
  List<Pet> _pets = [];
  int _pet = 0;
  List<Vaccine> _vaccines = [];
  List<Treatment> _treatments = [];
  List<MedicalDocument> _docs = [];
  bool _loading = true;
  HealthTip? _tip;
  bool _tipLoading = false;

  int get _vaccinesAlert => _vaccines
      .where((v) =>
          v.status == HealthStatus.late || v.status == HealthStatus.soon)
      .length;

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
    await _loadTip();
  }

  Future<void> _loadHealth() async {
    if (_pets.isEmpty) {
      if (mounted) {
        setState(() {
          _vaccines = [];
          _treatments = [];
          _docs = [];
          _tip = null;
        });
      }
      return;
    }
    final id = _pets[_pet].id!;
    final v = await _healthRepo.getVaccines(id);
    final t = await _healthRepo.getTreatments(id);
    final d = await _healthRepo.getDocuments(id);
    if (mounted) {
      setState(() {
        _vaccines = v;
        _treatments = t;
        _docs = d;
      });
    }
  }

  Future<void> _loadTip() async {
    if (_pets.isEmpty) return;
    setState(() => _tipLoading = true);
    final tip = await _tipService.getTipOfDay(_pets[_pet].species);
    if (!mounted) return;
    setState(() {
      _tip = tip;
      _tipLoading = false;
    });
  }

  Future<void> _openAdd(
    HealthRecordType type, {
    String? initialTitle,
    int? suggestedIntervalMonths,
  }) async {
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
          initialTitle: initialTitle,
          suggestedIntervalMonths: suggestedIntervalMonths,
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
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_health',
          onPressed: _showAddSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Santé',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (_pets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Ajoutez d’abord un animal',
                      style: TextStyle(color: AppColors.textSecondary),
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
                    await _loadTip();
                  },
                ),
                _HealthTipBanner(
                  tip: _tip,
                  loading: _tipLoading,
                  onRefresh: _loadTip,
                ),
                if (_vaccinesAlert > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: StatusPill(
                      '$_vaccinesAlert rappel${_vaccinesAlert > 1 ? 's' : ''} à surveiller',
                      AppColors.reminder,
                      icon: Icons.notification_important_rounded,
                    ),
                  ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Vaccins'),
                    Tab(text: 'Soins'),
                    Tab(text: 'Docs'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _vaccinesTab(),
                      _list(
                        empty: 'Aucun traitement',
                        children: _treatments.map(_treatmentCard),
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

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajouter',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              for (final type in HealthRecordType.values)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: IconBadge(type.icon, type.color, size: 42),
                  title: Text(
                    type.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAdd(type);
                  },
                ),
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
    final color = _statusColor(v.status);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          IconBadge(Icons.vaccines_rounded, AppColors.health, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(v.status.label, color),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editVaccine(v);
              } else if (value == 'delete') {
                _confirmDelete(
                  v.name,
                  () async {
                    await _healthRepo.deleteVaccine(v.id!);
                    await LocalNotifications.instance
                        .cancel(LocalNotifications.vaccineId(v.id!));
                  },
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editVaccine(Vaccine v) async {
    final name = TextEditingController(text: v.name);
    final date = TextEditingController(text: v.date);
    final next = TextEditingController(text: v.nextDate);
    final vet = TextEditingController(text: v.vet);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le vaccin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: date, decoration: const InputDecoration(labelText: 'Date (JJ/MM/AAAA)')),
              TextField(controller: next, decoration: const InputDecoration(labelText: 'Prochain rappel')),
              TextField(controller: vet, decoration: const InputDecoration(labelText: 'Vétérinaire')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true) return;
    final updated = v.copyWith(
      name: name.text.trim(),
      date: date.text.trim(),
      nextDate: next.text.trim(),
      vet: vet.text.trim(),
    );
    await _healthRepo.updateVaccine(updated);
    if (updated.id != null) {
      await LocalNotifications.instance.scheduleVaccine(
        id: updated.id!,
        name: updated.name,
        nextDate: updated.nextDate,
      );
    }
    await _loadHealth();
  }

  Widget _treatmentCard(Treatment t) {
    final color = t.isCompleted ? AppColors.health : AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(t.icon, color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      '${t.dosage} · ${t.frequency}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                t.isCompleted
                    ? 'Terminé'
                    : 'J${t.currentDay}/${t.totalDays}',
                color,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTreatment(t);
                  } else if (value == 'delete') {
                    _confirmDelete(
                      t.name,
                      () async {
                        await _healthRepo.deleteTreatment(t.id!);
                        await LocalNotifications.instance.cancel(
                            LocalNotifications.treatmentId(t.id!));
                      },
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: t.progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
          if (!t.isCompleted) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await _healthRepo.advanceTreatmentDay(t);
                  if (t.currentDay + 1 >= t.totalDays && t.id != null) {
                    await LocalNotifications.instance
                        .cancel(LocalNotifications.treatmentId(t.id!));
                  }
                  await _loadHealth();
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Jour pris'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editTreatment(Treatment t) async {
    final name = TextEditingController(text: t.name);
    final dosage = TextEditingController(text: t.dosage);
    final frequency = TextEditingController(text: t.frequency);
    final days = TextEditingController(text: '${t.totalDays}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le traitement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: dosage, decoration: const InputDecoration(labelText: 'Dosage')),
              TextField(controller: frequency, decoration: const InputDecoration(labelText: 'Fréquence')),
              TextField(
                controller: days,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durée (jours)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true) return;
    final total = int.tryParse(days.text.trim()) ?? t.totalDays;
    final updated = t.copyWith(
      name: name.text.trim(),
      dosage: dosage.text.trim(),
      frequency: frequency.text.trim(),
      totalDays: total.clamp(1, 365),
    );
    await _healthRepo.updateTreatment(updated);
    if (updated.id != null) {
      await LocalNotifications.instance.scheduleTreatment(
        id: updated.id!,
        name: updated.name,
        dosage: updated.dosage,
        active: !updated.isCompleted,
      );
    }
    await _loadHealth();
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
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: hasFile ? () => _openDocument(d) : null,
      child: Row(
        children: [
          !d.isPdf && hasFile
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(d.filePath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : IconBadge(
                  d.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  AppColors.primary,
                  size: 42,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.date} · ${d.isPdf ? 'PDF' : 'Image'}'
                  '${d.size == '—' || d.size.isEmpty ? '' : ' · ${d.size}'}'
                  '${hasFile ? '' : ' · manquant'}',
                  style: TextStyle(
                    color: hasFile
                        ? AppColors.textSecondary
                        : AppColors.reminder,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open' && hasFile) {
                _openDocument(d);
              } else if (value == 'delete') {
                _confirmDelete(
                  d.name,
                  () => _healthRepo.deleteDocument(d.id!),
                );
              }
            },
            itemBuilder: (_) => [
              if (hasFile)
                const PopupMenuItem(value: 'open', child: Text('Ouvrir')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vaccinesTab() {
    final pet = _pets[_pet];
    final suggestions = VaccineSuggestionService()
        .missingFor(pet: pet, recorded: _vaccines)
        .take(3)
        .toList();
    if (_vaccines.isEmpty && suggestions.isEmpty) {
      return const Center(
        child: Text(
          'Aucun vaccin',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (suggestions.isNotEmpty) ...[
          for (final s in suggestions) ...[
            _suggestionRow(s),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
        ],
        for (final v in _vaccines) ...[
          _vaccineCard(v),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _suggestionRow(VaccineSuggestion s) {
    final shortName = s.name.length > 42
        ? '${s.name.substring(0, 40)}…'
        : s.name;
    return AppCard(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      onTap: () => _openAdd(
        HealthRecordType.vaccine,
        initialTitle: s.name,
        suggestedIntervalMonths: s.suggestedIntervalMonths,
      ),
      child: Row(
        children: [
          const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Source WSAVA',
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: AppColors.primary,
            onPressed: () => launchUrl(
              Uri.parse(s.sourceUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
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
        child: Text(
          empty,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final c in items) ...[c, const SizedBox(height: 10)],
      ],
    );
  }
}

class _HealthTipBanner extends StatelessWidget {
  final HealthTip? tip;
  final bool loading;
  final VoidCallback onRefresh;

  const _HealthTipBanner({
    required this.tip,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && tip == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (tip == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: AppCard(
        color: AppColors.primaryLight,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tip!.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Open-Meteo',
              visualDensity: VisualDensity.compact,
              onPressed: () => launchUrl(
                Uri.parse(tip!.sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              color: AppColors.primary,
            ),
            IconButton(
              tooltip: 'Actualiser',
              visualDensity: VisualDensity.compact,
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
