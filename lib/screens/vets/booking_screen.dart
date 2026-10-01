import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class BookingScreen extends StatefulWidget {
  final Vet vet;
  final Appointment? existing;

  const BookingScreen({super.key, required this.vet, this.existing});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _days = [
    ('Mer', '30'),
    ('Jeu', '01'),
    ('Ven', '02'),
    ('Sam', '03'),
    ('Lun', '05'),
    ('Mar', '06'),
    ('Mer', '07'),
    ('Jeu', '08'),
  ];
  static const _morning = ['08:30', '09:00', '09:30', '10:00', '10:30', '11:00'];
  static const _afternoon = [
    '14:00',
    '14:30',
    '15:00',
    '16:00',
    '17:30',
    '18:00'
  ];
  static const _unavailable = {'09:00', '10:00', '15:00', '17:30'};
  static const _reasons = [
    'Consultation',
    'Vaccination',
    'Contrôle',
    'Urgence',
    'Chirurgie',
  ];

  int _pet = 0;
  int _day = 2;
  String _time = '10:30';
  String _reason = 'Vaccination';

  bool get _isEdit => widget.existing != null;

  Future<void> _confirm() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.health.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.health, size: 54),
              ),
              const SizedBox(height: 18),
              Text(_isEdit ? 'Rendez-vous modifié !' : 'Rendez-vous confirmé !',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${MockData.pets[_pet].name} a rendez-vous avec ${widget.vet.name} '
                'le ${_days[_day].$1}. ${_days[_day].$2} octobre à $_time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              const StatusPill('Rappel programmé 24 h avant', AppColors.vet,
                  icon: Icons.notifications_active_rounded),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Parfait !'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vet = widget.vet;
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier le rendez-vous' : 'Prendre rendez-vous')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _confirm,
            child: Text(_isEdit ? 'Enregistrer les modifications' : 'Confirmer le rendez-vous'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              child: Row(
                children: [
                  VetAvatar(vet, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vet.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(vet.clinic,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Text(vet.price,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
          _label('Animal'),
          PetSelector(
              selected: _pet, onChanged: (i) => setState(() => _pet = i)),
          _label('Octobre 2026'),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = i == _day;
                return GestureDetector(
                  onTap: () => setState(() => _day = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_days[i].$1,
                            style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_days[i].$2,
                            style: TextStyle(
                                color: selected ? Colors.white : AppColors.navy,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _label('Matin'),
          _slots(_morning),
          _label('Après-midi'),
          _slots(_afternoon),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legend(Colors.white, 'Disponible', border: true),
                _legend(AppColors.primary, 'Sélectionné'),
                _legend(AppColors.border, 'Indisponible'),
              ],
            ),
          ),
          _label('Motif de la visite'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LabeledField(
              label: 'Note pour le vétérinaire',
              hint: 'Symptômes, questions…',
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _legend(Color color, String label, {bool border = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: border ? Border.all(color: AppColors.border) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _slots(List<String> slots) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final s in slots)
              Builder(builder: (_) {
                final disabled = _unavailable.contains(s);
                final selected = s == _time;
                return GestureDetector(
                  onTap: disabled ? null : () => setState(() => _time = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: disabled
                          ? AppColors.border
                          : selected
                              ? AppColors.primary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? AppColors.textSecondary
                            : selected
                                ? Colors.white
                                : AppColors.navy,
                        decoration:
                            disabled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
}
