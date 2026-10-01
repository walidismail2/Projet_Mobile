import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class DietFormScreen extends StatefulWidget {
  const DietFormScreen({super.key});

  @override
  State<DietFormScreen> createState() => _DietFormScreenState();
}

class _DietFormScreenState extends State<DietFormScreen> {
  static const _dietTypes = [
    'Croquettes',
    'Pâtée',
    'Mixte',
    'BARF',
    'Fait maison',
  ];
  static const _goals = [
    'Maintien du poids',
    'Perte de poids',
    'Prise de poids',
    'Hypoallergénique',
  ];

  String _diet = 'Mixte';
  String _goal = 'Maintien du poids';
  double _mealsPerDay = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Régime alimentaire')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _Label('Type de régime'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _dietTypes)
                ChoiceChip(
                  label: Text(d),
                  selected: _diet == d,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _diet = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _Label('Objectif'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _goals)
                ChoiceChip(
                  label: Text(g),
                  selected: _goal == g,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _goal = g),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const LabeledField(
            label: 'Marque / produit',
            hint: 'Ex : Royal Canin Golden',
            icon: Icons.shopping_bag_outlined,
            initialValue: 'Royal Canin Golden',
          ),
          const _Label('Nombre de repas par jour'),
          AppCard(
            child: Column(
              children: [
                Text('${_mealsPerDay.round()} repas',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
                Slider(
                  value: _mealsPerDay,
                  min: 1,
                  max: 6,
                  divisions: 5,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _mealsPerDay = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Ration / jour (g)',
                  hint: '350',
                  icon: Icons.scale_rounded,
                  initialValue: '350',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Calories (kcal)',
                  hint: '1120',
                  icon: Icons.local_fire_department_outlined,
                  initialValue: '1120',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const LabeledField(
            label: 'Eau recommandée (L / jour)',
            hint: '1,4',
            icon: Icons.water_drop_outlined,
            initialValue: '1,4',
          ),
          const LabeledField(
            label: 'Remarques',
            hint: 'Recommandations du vétérinaire…',
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnack(context, 'Régime alimentaire enregistré');
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.navy)),
    );
  }
}
