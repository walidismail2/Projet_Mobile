import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class CustomReminderScreen extends StatefulWidget {
  const CustomReminderScreen({super.key});

  @override
  State<CustomReminderScreen> createState() => _CustomReminderScreenState();
}

class _CustomReminderScreenState extends State<CustomReminderScreen> {
  static const _icons = ['✨', '🛁', '💊', '🦴', '🚶', '✂️', '🧸', '🏥'];
  static const _repeats = [
    'Une fois',
    'Chaque jour',
    'Chaque semaine',
    'Chaque mois',
    'Chaque année',
  ];

  int _pet = 0;
  String _icon = '✨';
  String _repeat = 'Chaque semaine';
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  DateTime _date = DateTime(2026, 10, 3);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Rappel personnalisé')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnack(context, 'Rappel créé 🔔');
            },
            child: const Text('Créer le rappel'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('Icône', style: text.titleMedium),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _icons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _icon = _icons[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _icon == _icons[i]
                        ? AppColors.reminder.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _icon == _icons[i]
                          ? AppColors.reminder
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(_icons[i], style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text('Animal', style: text.titleMedium),
          ),
          PetSelector(
              selected: _pet, onChanged: (i) => setState(() => _pet = i)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LabeledField(
                  label: 'Titre',
                  hint: 'Ex : Brossage, bain, promenade…',
                  icon: Icons.title_rounded,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.event_rounded,
                        label: 'Date',
                        value:
                            '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2030),
                            initialDate: _date,
                          );
                          if (d != null) setState(() => _date = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.access_time_rounded,
                        label: 'Heure',
                        value: _time.format(context),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _time);
                          if (t != null) setState(() => _time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Répétition', style: text.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _repeats)
                      ChoiceChip(
                        label: Text(r),
                        selected: _repeat == r,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _repeat = r),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const LabeledField(
                  label: 'Note',
                  hint: 'Détails du rappel (facultatif)',
                  maxLines: 3,
                ),
                AppCard(
                  child: Row(
                    children: [
                      Text(_icon, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Aperçu de la notification',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                '$_repeat à ${_time.format(context)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy)),
                          ],
                        ),
                      ),
                      const Icon(Icons.notifications_active_rounded,
                          color: AppColors.reminder),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon, AppColors.reminder, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
