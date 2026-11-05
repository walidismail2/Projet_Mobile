import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/food_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../widgets/common.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Petit-déjeuner');
  final _food = TextEditingController();
  final _qty = TextEditingController(text: '100 g');
  final _cal = TextEditingController(text: '300');
  final _time = TextEditingController(text: '08:00');
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
    _name.dispose();
    _food.dispose();
    _qty.dispose();
    _cal.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _pets.isEmpty) return;
    await FoodRepository().insertMeal(Meal(
      petId: _pets[_pet].id!,
      name: _name.text.trim(),
      time: _time.text.trim(),
      food: _food.text.trim(),
      quantity: _qty.text.trim(),
      calories: int.tryParse(_cal.text) ?? 0,
      done: false,
      icon: Icons.restaurant_rounded,
    ));
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
                  LabeledField(
                      label: 'Type',
                      hint: 'Petit-déjeuner',
                      controller: _name,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null),
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
