import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  static const _types = [
    ('Croquettes', '🥣'),
    ('Pâtée', '🥫'),
    ('Fait maison', '🍗'),
    ('Friandise', '🦴'),
  ];
  static const _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  int _pet = 0;
  String _type = 'Croquettes';
  int _quantity = 120;
  String _unit = 'g';
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 30);
  final Set<int> _days = {0, 1, 2, 3, 4, 5, 6};
  bool _reminder = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un repas')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnack(context, 'Repas ajouté au planning 🍖');
            },
            child: const Text('Enregistrer le repas'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _label('Animal'),
          PetSelector(
              selected: _pet, onChanged: (i) => setState(() => _pet = i)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LabeledField(
                  label: 'Nom du repas',
                  hint: 'Ex : Dîner',
                  icon: Icons.restaurant_menu_rounded,
                ),
                const Text('Type d\'aliment',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (name, emoji) in _types)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == name
                                  ? AppColors.food.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _type == name
                                    ? AppColors.food
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const LabeledField(
                  label: 'Aliment',
                  hint: 'Ex : Croquettes Royal Canin',
                  icon: Icons.shopping_bag_outlined,
                ),
                const Text('Quantité',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 10),
                AppCard(
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => setState(() =>
                            _quantity = (_quantity - 10).clamp(0, 2000)),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('$_quantity',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navy)),
                            const SizedBox(height: 6),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: AppColors.primaryLight,
                                selectedForegroundColor: AppColors.primary,
                                visualDensity: VisualDensity.compact,
                              ),
                              segments: const [
                                ButtonSegment(value: 'g', label: Text('g')),
                                ButtonSegment(value: 'ml', label: Text('ml')),
                                ButtonSegment(
                                    value: 'unité', label: Text('unité')),
                              ],
                              selected: {_unit},
                              onSelectionChanged: (s) =>
                                  setState(() => _unit = s.first),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _quantity += 10),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Heure',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 10),
                AppCard(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  child: Row(
                    children: [
                      const IconBadge(Icons.access_time_rounded, AppColors.food,
                          size: 40),
                      const SizedBox(width: 12),
                      Text(_time.format(context),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Répéter',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < _weekDays.length; i++)
                      GestureDetector(
                        onTap: () => setState(() =>
                            _days.contains(i) ? _days.remove(i) : _days.add(i)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _days.contains(i)
                                ? AppColors.primary
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _days.contains(i)
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Text(_weekDays[i],
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _days.contains(i)
                                      ? Colors.white
                                      : AppColors.navy)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                    secondary: const IconBadge(
                        Icons.notifications_active_rounded, AppColors.reminder,
                        size: 40),
                    title: const Text('Rappel de repas',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    subtitle: const Text('Notification à l\'heure du repas'),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.navy)),
      );
}
