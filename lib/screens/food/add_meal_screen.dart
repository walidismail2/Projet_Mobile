import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/food_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../services/local_notifications.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

const _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner'];

const _mealTimes = {
  'Petit-déjeuner': '08:00',
  'Déjeuner': '12:30',
  'Dîner': '19:00',
};

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _food = TextEditingController();
  final _qty = TextEditingController(text: '100 g');
  final _cal = TextEditingController(text: '300');
  final _time = TextEditingController(text: '08:00');
  List<Pet> _pets = [];
  int _pet = 0;
  String _type = _mealTypes.first;

  @override
  void initState() {
    super.initState();
    PetRepository().getByOwner(Session.instance.userId!).then((p) {
      if (mounted) setState(() => _pets = p);
    });
  }

  @override
  void dispose() {
    _food.dispose();
    _qty.dispose();
    _cal.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _pets.isEmpty) return;
    final mealId = await FoodRepository().insertMeal(Meal(
      petId: _pets[_pet].id!,
      name: _type,
      time: _time.text.trim(),
      food: _food.text.trim(),
      quantity: _qty.text.trim(),
      calories: int.tryParse(_cal.text) ?? 0,
      done: false,
      icon: Icons.restaurant_rounded,
    ));
    await LocalNotifications.instance.scheduleMeal(
      id: mealId,
      name: _type,
      time: _time.text.trim(),
      recordInApp: true,
    );
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnack(context, 'Repas ajouté');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un repas')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            PetSelector(
                pets: _pets,
                selected: _pet,
                onChanged: (i) => setState(() => _pet = i)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_type),
                          initialValue: _type,
                          items: [
                            for (final type in _mealTypes)
                              DropdownMenuItem(value: type, child: Text(type)),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _type = value;
                              _time.text = _mealTimes[value] ?? _time.text;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Choisir un type',
                          ),
                        ),
                      ],
                    ),
                  ),
                  LabeledField(
                      label: 'Aliment',
                      hint: 'Croquettes…',
                      controller: _food,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null),
                  LabeledField(
                      label: 'Quantité', hint: '100 g', controller: _qty),
                  LabeledField(
                      label: 'Calories',
                      hint: '300',
                      controller: _cal,
                      keyboardType: TextInputType.number),
                  LabeledField(
                      label: 'Heure', hint: '08:00', controller: _time),
                  FilledButton(
                      onPressed: _save,
                      child: const Text('Enregistrer le repas')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
