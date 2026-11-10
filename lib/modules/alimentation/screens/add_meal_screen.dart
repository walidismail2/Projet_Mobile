import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';

const _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner'];

const _mealTimes = {
  'Petit-déjeuner': '08:00',
  'Déjeuner': '12:30',
  'Dîner': '19:00',
};

class AddMealScreen extends StatefulWidget {
  final Meal? meal;

  const AddMealScreen({super.key, this.meal});

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
  bool get _isEdit => widget.meal?.id != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.meal;
    if (existing != null) {
      _type = _mealTypes.contains(existing.name)
          ? existing.name
          : _mealTypes.first;
      _food.text = existing.food;
      _qty.text = existing.quantity;
      _cal.text = '${existing.calories}';
      _time.text = existing.time;
    }
    PetRepository().getByOwner(Session.instance.userId!).then((p) {
      if (!mounted) return;
      var index = 0;
      if (existing?.petId != null) {
        final i = p.indexWhere((pet) => pet.id == existing!.petId);
        if (i >= 0) index = i;
      }
      setState(() {
        _pets = p;
        _pet = index;
      });
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
    final repo = FoodRepository();
    final meal = Meal(
      id: widget.meal?.id,
      petId: _pets[_pet].id!,
      name: _type,
      time: _time.text.trim(),
      food: _food.text.trim(),
      quantity: _qty.text.trim(),
      calories: int.tryParse(_cal.text) ?? 0,
      done: widget.meal?.done ?? false,
      icon: Icons.restaurant_rounded,
    );
    if (_isEdit) {
      await repo.updateMeal(meal);
      await LocalNotifications.instance.scheduleMeal(
        id: meal.id!,
        name: meal.name,
        time: meal.time,
      );
    } else {
      final mealId = await repo.insertMeal(meal);
      await LocalNotifications.instance.scheduleMeal(
        id: mealId,
        name: meal.name,
        time: meal.time,
        recordInApp: true,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    showSuccessSnack(
        context, _isEdit ? 'Repas modifié' : 'Repas ajouté');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier le repas' : 'Ajouter un repas')),
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
                      child: Text(_isEdit
                          ? 'Enregistrer les modifications'
                          : 'Enregistrer le repas')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
