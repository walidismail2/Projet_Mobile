import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_example/core/data/document_storage.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/sante/repositories/health_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';

enum HealthRecordType {
  vaccine('Vaccin', Icons.vaccines_rounded, AppColors.health),
  treatment('Traitement', Icons.medication_rounded, AppColors.primary),
  document('Document', Icons.description_rounded, AppColors.vet);

  final String label;
  final IconData icon;
  final Color color;
  const HealthRecordType(this.label, this.icon, this.color);
}

const _frequencies = [
  '1 fois / jour',
  '2 fois / jour',
  '3 fois / jour',
  'Tous les 2 jours',
  '1 fois / semaine',
  'Selon besoin',
];

class AddHealthRecordScreen extends StatefulWidget {
  final HealthRecordType type;
  final int? initialPetId;
  final String? initialTitle;
  final int? suggestedIntervalMonths;

  const AddHealthRecordScreen({
    super.key,
    required this.type,
    this.initialPetId,
    this.initialTitle,
    this.suggestedIntervalMonths,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _nextDate = TextEditingController();
  final _vet = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();
  final _days = TextEditingController(text: '7');
  final _health = HealthRepository();

  List<Pet> _pets = [];
  int _pet = 0;
  String _frequency = _frequencies.first;
  bool _isPdf = true;
  String? _pickedPath;
  String? _pickedName;
  String? _pickedSize;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = formatFrDate(DateTime.now());
    _date.text = today;
    final title = widget.initialTitle?.trim();
    if (title != null && title.isNotEmpty) {
      _title.text = title;
    }
    final months = widget.suggestedIntervalMonths;
    if (months != null && months > 0) {
      final next = DateTime.now().add(Duration(days: months * 30));
      _nextDate.text = formatFrDate(next);
    }
    _load();
  }

  Future<void> _load() async {
    final pets = await PetRepository().getByOwner(Session.instance.userId!);
    if (!mounted) return;
    var index = 0;
    if (widget.initialPetId != null && pets.isNotEmpty) {
      final i = pets.indexWhere((p) => p.id == widget.initialPetId);
      if (i >= 0) index = i;
    }
    setState(() {
      _pets = pets;
      _pet = index;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _nextDate.dispose();
    _vet.dispose();
    _dosage.dispose();
    _notes.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl, {DateTime? min}) async {
    final parsed = parseFrDate(ctrl.text);
    final d = await showDatePicker(
      context: context,
      firstDate: min ?? DateTime(2015),
      lastDate: DateTime(2040),
      initialDate: parsed ?? DateTime.now(),
    );
    if (d != null) {
      ctrl.text = formatFrDate(d);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _pets.isEmpty || _saving) return;
    setState(() => _saving = true);
    final petId = _pets[_pet].id!;
    final type = widget.type;
    try {
      switch (type) {
        case HealthRecordType.vaccine:
          final next = _nextDate.text.trim();
          final vaccineId = await _health.insertVaccine(Vaccine(
            petId: petId,
            name: _title.text.trim(),
            date: _date.text.trim(),
            nextDate: next,
            vet: _vet.text.trim().isEmpty ? '—' : _vet.text.trim(),
            status: healthStatusFromNextDate(next),
          ));
          await LocalNotifications.instance.scheduleVaccine(
            id: vaccineId,
            name: _title.text.trim(),
            nextDate: next,
            recordInApp: true,
          );
        case HealthRecordType.treatment:
          final total = int.tryParse(_days.text.trim()) ?? 7;
          final treatmentName = _title.text.trim();
          final dosage =
              _dosage.text.trim().isEmpty ? '—' : _dosage.text.trim();
          final treatmentId = await _health.insertTreatment(Treatment(
            petId: petId,
            name: treatmentName,
            dosage: dosage,
            frequency: _frequency,
            currentDay: 0,
            totalDays: total.clamp(1, 365),
            icon: Icons.medication_rounded,
          ));
          await LocalNotifications.instance.scheduleTreatment(
            id: treatmentId,
            name: treatmentName,
            dosage: dosage,
            active: true,
            recordInApp: true,
          );
        case HealthRecordType.document:
          if (_pickedPath == null) {
            if (!mounted) return;
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Choisissez un fichier')),
            );
            return;
          }
          final saved = await DocumentStorage.saveLocal(
            _pickedPath!,
            isPdf: _isPdf,
          );
          await _health.insertDocument(MedicalDocument(
            petId: petId,
            name: _title.text.trim(),
            date: _date.text.trim(),
            size: saved.sizeLabel,
            isPdf: _isPdf,
            filePath: saved.path,
          ));
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      showSuccessSnack(context, '${type.label} enregistré');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’enregistrer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_pets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Ajouter : ${widget.type.label}')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ajoutez d’abord un animal pour enregistrer un suivi santé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ajouter : ${widget.type.label}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            PetSelector(
              pets: _pets,
              selected: _pet,
              onChanged: (i) => setState(() => _pet = i),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._fieldsForType(),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldsForType() {
    switch (widget.type) {
      case HealthRecordType.vaccine:
        return [
          LabeledField(
            label: 'Nom du vaccin',
            hint: 'Ex. Rage, CHPPi…',
            controller: _title,
            validator: _required,
          ),
          LabeledField(
            label: 'Date d’injection',
            hint: 'JJ/MM/AAAA',
            controller: _date,
            readOnly: true,
            onTap: () => _pickDate(_date),
            validator: _required,
          ),
          LabeledField(
            label: 'Prochain rappel',
            hint: 'JJ/MM/AAAA',
            controller: _nextDate,
            readOnly: true,
            onTap: () {
              final min = parseFrDate(_date.text) ?? DateTime.now();
              _pickDate(_nextDate, min: min);
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Rappel requis';
              final next = parseFrDate(v);
              if (next == null) return 'Date invalide';
              final inj = parseFrDate(_date.text);
              if (inj != null && next.isBefore(inj)) {
                return 'Doit être après l’injection';
              }
              return null;
            },
          ),
          LabeledField(
            label: 'Vétérinaire',
            hint: 'Dr. …',
            controller: _vet,
          ),
          if (_nextDate.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusPill(
                healthStatusFromNextDate(_nextDate.text).label,
                _statusColor(healthStatusFromNextDate(_nextDate.text)),
              ),
            ),
        ];
      case HealthRecordType.treatment:
        return [
          LabeledField(
            label: 'Médicament / traitement',
            hint: 'Ex. Antibiotique…',
            controller: _title,
            validator: _required,
          ),
          LabeledField(
            label: 'Dosage',
            hint: 'Ex. 1 comprimé, 0,5 ml…',
            controller: _dosage,
            validator: _required,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fréquence',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(_frequency),
                  initialValue: _frequency,
                  items: [
                    for (final f in _frequencies)
                      DropdownMenuItem(value: f, child: Text(f)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _frequency = v);
                  },
                  decoration: const InputDecoration(hintText: 'Fréquence'),
                ),
              ],
            ),
          ),
          LabeledField(
            label: 'Durée (jours)',
            hint: '7',
            controller: _days,
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) return 'Durée invalide';
              if (n > 365) return 'Max. 365 jours';
              return null;
            },
          ),
          LabeledField(
            label: 'Date de début',
            hint: 'JJ/MM/AAAA',
            controller: _date,
            readOnly: true,
            onTap: () => _pickDate(_date),
            validator: _required,
          ),
          LabeledField(
            label: 'Notes',
            hint: 'Consignes, remarques…',
            controller: _notes,
            maxLines: 3,
          ),
        ];
      case HealthRecordType.document:
        return [
          LabeledField(
            label: 'Nom du document',
            hint: 'Ex. Analyse sang…',
            controller: _title,
            validator: _required,
          ),
          LabeledField(
            label: 'Date',
            hint: 'JJ/MM/AAAA',
            controller: _date,
            readOnly: true,
            onTap: () => _pickDate(_date),
            validator: _required,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type de fichier',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('PDF'),
                      icon: Icon(Icons.picture_as_pdf),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Image'),
                      icon: Icon(Icons.image),
                    ),
                  ],
                  selected: {_isPdf},
                  onSelectionChanged: (s) {
                    setState(() {
                      _isPdf = s.first;
                      _pickedPath = null;
                      _pickedName = null;
                      _pickedSize = null;
                    });
                  },
                ),
              ],
            ),
          ),
          _FilePickerCard(
            isPdf: _isPdf,
            pickedName: _pickedName,
            pickedSize: _pickedSize,
            pickedPath: _pickedPath,
            onPickPdf: _pickPdf,
            onPickGallery: () => _pickImage(ImageSource.gallery),
            onPickCamera: () => _pickImage(ImageSource.camera),
            onClear: () => setState(() {
              _pickedPath = null;
              _pickedName = null;
              _pickedSize = null;
            }),
          ),
        ];
    }
  }

  Future<void> _pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final path = file?.path;
    if (file == null || path == null) return;
    final bytes = file.lengthSync() ?? await file.length() ?? 0;
    setState(() {
      _isPdf = true;
      _pickedPath = path;
      _pickedName = file.name;
      _pickedSize = bytes > 0 ? DocumentStorage.formatBytes(bytes) : null;
      if (_title.text.trim().isEmpty) {
        _title.text = p.basenameWithoutExtension(file.name);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.length();
    setState(() {
      _isPdf = false;
      _pickedPath = x.path;
      _pickedName = x.name;
      _pickedSize = DocumentStorage.formatBytes(bytes);
      if (_title.text.trim().isEmpty) {
        _title.text = p.basenameWithoutExtension(x.name);
      }
    });
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requis' : null;

  Color _statusColor(HealthStatus s) => switch (s) {
        HealthStatus.upToDate => AppColors.health,
        HealthStatus.soon => AppColors.food,
        HealthStatus.late => AppColors.reminder,
      };
}

class _FilePickerCard extends StatelessWidget {
  final bool isPdf;
  final String? pickedName;
  final String? pickedSize;
  final String? pickedPath;
  final VoidCallback onPickPdf;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClear;

  const _FilePickerCard({
    required this.isPdf,
    required this.pickedName,
    required this.pickedSize,
    required this.pickedPath,
    required this.onPickPdf,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = pickedPath != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fichier',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (hasFile) ...[
              if (!isPdf && pickedPath != null && File(pickedPath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(pickedPath!),
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Row(
                  children: [
                    IconBadge(
                      isPdf ? Icons.picture_as_pdf : Icons.image,
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickedName ?? 'Fichier',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (pickedSize != null)
                            Text(
                              pickedSize!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onClear, child: const Text('Retirer')),
              ),
            ] else if (isPdf) ...[
              OutlinedButton.icon(
                onPressed: onPickPdf,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choisir un PDF'),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Appareil photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
