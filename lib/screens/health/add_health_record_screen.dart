import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

enum HealthRecordType {
  vaccine('Vaccin', 'Enregistrer une vaccination', Icons.vaccines_rounded,
      AppColors.health),
  treatment('Traitement', 'Médicament, vermifuge, anti-puces…',
      Icons.medication_rounded, AppColors.purple),
  consultation('Consultation', 'Visite, examen, intervention',
      Icons.monitor_heart_rounded, AppColors.vet),
  allergy('Allergie', 'Allergie ou information importante',
      Icons.warning_amber_rounded, AppColors.reminder),
  document('Document', 'Ordonnance, radio, analyse…',
      Icons.description_rounded, AppColors.food);

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const HealthRecordType(this.label, this.description, this.icon, this.color);
}

class AddHealthRecordScreen extends StatefulWidget {
  final HealthRecordType type;

  const AddHealthRecordScreen({super.key, required this.type});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  int _pet = 0;
  bool _reminder = true;
  String _severity = 'Modérée';

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter : ${type.label.toLowerCase()}')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconBadge(type.icon, type.color, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(type.description,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text('Pour quel animal ?',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.navy)),
          ),
          PetSelector(
              selected: _pet, onChanged: (i) => setState(() => _pet = i)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._fieldsFor(type),
                if (type == HealthRecordType.vaccine ||
                    type == HealthRecordType.treatment)
                  AppCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _reminder,
                      onChanged: (v) => setState(() => _reminder = v),
                      secondary: const IconBadge(
                          Icons.notifications_active_rounded,
                          AppColors.reminder,
                          size: 40),
                      title: const Text('Activer le rappel',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      subtitle: Text(type == HealthRecordType.vaccine
                          ? '7 jours avant la date de rappel'
                          : 'À chaque prise'),
                    ),
                  ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showSuccessSnack(context, '${type.label} ajouté(e)');
                  },
                  child: const Text('Enregistrer'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LabeledField _dateField(String label) => LabeledField(
        label: label,
        hint: 'JJ/MM/AAAA',
        icon: Icons.event_outlined,
        readOnly: true,
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime(2015),
          lastDate: DateTime(2035),
          initialDate: DateTime.now(),
        ),
      );

  List<Widget> _fieldsFor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccine:
        return [
          const LabeledField(
              label: 'Nom du vaccin',
              hint: 'Ex : Rage, CHPPi…',
              icon: Icons.vaccines_outlined),
          Row(children: [
            Expanded(child: _dateField('Date')),
            const SizedBox(width: 12),
            Expanded(child: _dateField('Prochain rappel')),
          ]),
          const LabeledField(
              label: 'Vétérinaire',
              hint: 'Ex : Dr. Martin',
              icon: Icons.local_hospital_outlined),
          const LabeledField(
              label: 'N° de lot',
              hint: 'Facultatif',
              icon: Icons.qr_code_rounded),
        ];
      case HealthRecordType.treatment:
        return [
          const LabeledField(
              label: 'Médicament',
              hint: 'Ex : Clavubactin',
              icon: Icons.medication_outlined),
          const Row(children: [
            Expanded(
                child: LabeledField(
                    label: 'Dosage', hint: 'Ex : 250 mg', icon: Icons.scale)),
            SizedBox(width: 12),
            Expanded(
                child: LabeledField(
                    label: 'Fréquence',
                    hint: '2x / jour',
                    icon: Icons.repeat_rounded)),
          ]),
          Row(children: [
            Expanded(child: _dateField('Début')),
            const SizedBox(width: 12),
            Expanded(child: _dateField('Fin')),
          ]),
          const LabeledField(
              label: 'Instructions',
              hint: 'Ex : à donner pendant le repas',
              maxLines: 3),
        ];
      case HealthRecordType.consultation:
        return [
          const LabeledField(
              label: 'Motif',
              hint: 'Ex : contrôle annuel',
              icon: Icons.description_outlined),
          _dateField('Date'),
          const LabeledField(
              label: 'Vétérinaire',
              hint: 'Ex : Dr. Martin',
              icon: Icons.local_hospital_outlined),
          const LabeledField(
              label: 'Diagnostic / compte rendu',
              hint: 'Notes du vétérinaire…',
              maxLines: 4),
        ];
      case HealthRecordType.allergy:
        return [
          const LabeledField(
              label: 'Allergène',
              hint: 'Ex : poulet, pollen…',
              icon: Icons.warning_amber_rounded),
          const Text('Sévérité',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (final s in ['Légère', 'Modérée', 'Sévère'])
                ChoiceChip(
                  label: Text(s),
                  selected: _severity == s,
                  onSelected: (_) => setState(() => _severity = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const LabeledField(
              label: 'Symptômes / réaction',
              hint: 'Ex : démangeaisons, vomissements…',
              maxLines: 3),
        ];
      case HealthRecordType.document:
        return [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded,
                    size: 48, color: AppColors.primary),
                SizedBox(height: 8),
                Text('Touchez pour choisir un fichier',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text('PDF, JPG ou PNG · 10 Mo max',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {},
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Fichiers'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const LabeledField(
              label: 'Nom du document',
              hint: 'Ex : Radio hanche',
              icon: Icons.description_outlined),
          _dateField('Date du document'),
        ];
    }
  }
}
