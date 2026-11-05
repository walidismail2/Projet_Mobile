import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../repositories/reminder_repository.dart';
import '../../widgets/common.dart';

class CustomReminderScreen extends StatefulWidget {
  const CustomReminderScreen({super.key});

  @override
  State<CustomReminderScreen> createState() => _CustomReminderScreenState();
}

class _CustomReminderScreenState extends State<CustomReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController(text: '10:00');
  String _category = 'Toilettage';
  String _repeat = 'Hebdo';
  List<Pet> _pets = [];
  int _pet = 0;

  @override
  void initState() {
    super.initState();
    PetRepository().getByOwner(Session.instance.userId!).then((p) {
      if (mounted) setState(() => _pets = p);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ReminderRepository().insertCustomReminder(CustomReminder(
      petId: _pets.isEmpty ? null : _pets[_pet].id,
      title: _title.text.trim(),
      category: _category,
      date: _date.text.trim(),
      time: _time.text.trim(),
      repeat: _repeat,
      note: _note.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnack(context, 'Rappel créé');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau rappel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (_pets.isNotEmpty)
              PetSelector(
                  pets: _pets,
                  selected: _pet,
                  onChanged: (i) => setState(() => _pet = i)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  LabeledField(
                    label: 'Titre',
                    hint: 'Toilettage…',
                    controller: _title,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in [
                        'Toilettage',
                        'Médicament',
                        'Promenade',
                        'Griffes'
                      ])
                        ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'Date',
                    hint: 'JJ/MM/AAAA',
                    controller: _date,
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        initialDate: DateTime.now(),
                      );
                      if (d != null) {
                        _date.text =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                        setState(() {});
                      }
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Date requise' : null,
                  ),
                  LabeledField(
                      label: 'Heure', hint: '10:00', controller: _time),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in [
                        'Une fois',
                        'Quotidien',
                        'Hebdo',
                        'Mensuel'
                      ])
                        ChoiceChip(
                          label: Text(r),
                          selected: _repeat == r,
                          onSelected: (_) => setState(() => _repeat = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                      label: 'Note',
                      hint: 'Optionnel',
                      controller: _note,
                      maxLines: 3),
                  FilledButton(
                      onPressed: _save,
                      child: const Text('Créer le rappel')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
