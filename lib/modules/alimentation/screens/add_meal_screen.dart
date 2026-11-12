import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/screens/product_search_screen.dart';
import 'package:flutter_example/modules/alimentation/services/food_safety_service.dart';
import 'package:flutter_example/modules/alimentation/services/pet_food_api_service.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';

/// Types de repas (aussi utilisés comme filtre dans l'historique).
const mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];

const _mealTimes = {
  'Petit-déjeuner': '08:00',
  'Déjeuner': '12:30',
  'Dîner': '19:00',
  'Collation': '16:00',
};

class AddMealScreen extends StatefulWidget {
  final Meal? meal;

  /// Jour affiché dans l'écran Alimentation (date proposée si ponctuel).
  final DateTime? initialDate;
  final int? initialPetId;

  const AddMealScreen({
    super.key,
    this.meal,
    this.initialDate,
    this.initialPetId,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _food = TextEditingController();
  final _qty = TextEditingController(text: '100 g');
  final _cal = TextEditingController(text: '300');
  final _time = TextEditingController(text: '08:00');
  final _dateText = TextEditingController();
  final _foodRepo = FoodRepository();
  List<Pet> _pets = [];
  List<FoodItem> _vetItems = [];
  int _pet = 0;
  String _type = mealTypes.first;
  bool _daily = true;
  late DateTime _date;
  PetFoodProduct? _product;
  double? _kcal100;
  bool _saving = false;

  bool get _isEdit => widget.meal?.id != null;
  Pet? get _currentPet => _pets.isEmpty ? null : _pets[_pet];

  @override
  void initState() {
    super.initState();
    final existing = widget.meal;
    _date = dayOnly(existing?.date ?? widget.initialDate ?? DateTime.now());
    if (existing != null) {
      _type = mealTypes.contains(existing.name)
          ? existing.name
          : mealTypes.first;
      _food.text = existing.food;
      _qty.text = existing.quantity;
      _cal.text = '${existing.calories}';
      _time.text = existing.time;
      _daily = existing.isDaily;
      _kcal100 = existing.kcalPer100g;
      if (existing.productCode != null) {
        PetFoodApiService().getByCode(existing.productCode!).then((p) {
          if (mounted && p != null) setState(() => _product = p);
        });
      }
    }
    _dateText.text = formatFrDate(_date);
    _qty.addListener(_recomputeCalories);
    PetRepository().getByOwner(Session.instance.userId!).then((p) async {
      if (!mounted) return;
      final wanted = existing?.petId ?? widget.initialPetId;
      final i = p.indexWhere((pet) => pet.id == wanted);
      setState(() {
        _pets = p;
        _pet = i >= 0 ? i : 0;
      });
      await _loadVetItems();
    });
  }

  @override
  void dispose() {
    _food.dispose();
    _qty.dispose();
    _cal.dispose();
    _time.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _loadVetItems() async {
    final pet = _currentPet;
    if (pet?.id == null) return;
    final allowed = await _foodRepo.getFoodItems(pet!.id!, allowed: true);
    final forbidden = await _foodRepo.getFoodItems(pet.id!, allowed: false);
    if (mounted) setState(() => _vetItems = [...allowed, ...forbidden]);
  }

  int? get _grams => parseGrams(_qty.text);

  /// kcal = grammes × kcal/100 g du produit choisi.
  void _recomputeCalories() {
    final g = _grams;
    if (_kcal100 == null || g == null) return;
    final kcal = (g * _kcal100! / 100).round();
    if (_cal.text != '$kcal') _cal.text = '$kcal';
    setState(() {});
  }

  Future<void> _pickProduct() async {
    final pet = _currentPet;
    if (pet == null) return;
    final p = await Navigator.push<PetFoodProduct>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductSearchScreen(
          pet: pet,
          vetItems: _vetItems,
          initialQuery: _product == null ? _food.text.trim() : '',
        ),
      ),
    );
    if (p == null || !mounted) return;
    setState(() {
      _product = p;
      _kcal100 = p.kcalPer100g;
      _food.text = p.displayName;
    });
    _recomputeCalories();
  }

  void _unlinkProduct() => setState(() {
    _product = null;
    _kcal100 = null;
  });

  Future<void> _pickDate() async {
    final today = dayOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _dateText.text = formatFrDate(d);
    });
  }

  /// Alertes sur le nom de l'aliment (toutes) et les ingrédients du produit
  /// (toxique / interdit véto uniquement).
  List<SafetyResult> _safetyAlerts() {
    final species = _currentPet?.species ?? '';
    final all = [
      ...FoodSafetyService.checkText(
        _food.text,
        species: species,
        vetItems: _vetItems,
      ),
      if (_product != null)
        ...FoodSafetyService.checkText(
          _product!.ingredients,
          species: species,
          vetItems: _vetItems,
          includeCaution: false,
        ),
    ];
    final seen = <String>{};
    return [
      for (final a in all)
        if (seen.add(a.title)) a,
    ];
  }

  Future<bool> _confirmAlerts(List<SafetyResult> alerts) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.reminder,
          size: 40,
        ),
        title: const Text('Aliment à risque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${a.level.icon} ${a.level.label} : ${a.title}\n${a.reason}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Modifier'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer quand même'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _pets.isEmpty) return;
    final alerts = _safetyAlerts();
    if (alerts.isNotEmpty && !await _confirmAlerts(alerts)) return;
    setState(() => _saving = true);
    final existing = widget.meal;
    final meal = Meal(
      id: existing?.id,
      petId: _pets[_pet].id!,
      name: _type,
      time: _time.text.trim(),
      food: _food.text.trim(),
      quantity: _qty.text.trim(),
      calories: int.tryParse(_cal.text) ?? 0,
      icon: Icons.restaurant_rounded,
      date: _daily ? null : _date,
      // Un repas quotidien modifié garde son historique.
      createdOn: (existing?.isDaily ?? false) && _daily
          ? existing!.createdOn
          : null,
      productCode: _product?.code,
      kcalPer100g: _product == null ? null : _kcal100,
    );
    final id = _isEdit ? meal.id! : await _foodRepo.insertMeal(meal);
    if (_isEdit) await _foodRepo.updateMeal(meal);
    await LocalNotifications.instance.scheduleMeal(
      id: id,
      name: meal.name,
      time: meal.time,
      date: meal.date,
      recordInApp: !_isEdit,
    );
    if (!mounted) return;
    showSuccessSnack(context, _isEdit ? 'Repas modifié' : 'Repas ajouté');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final g = _grams;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le repas' : 'Ajouter un repas'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            PetSelector(
              pets: _pets,
              selected: _pet,
              onChanged: (i) async {
                setState(() => _pet = i);
                await _loadVetItems();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('Fréquence'),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.repeat_rounded),
                        label: Text('Tous les jours'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.event_rounded),
                        label: Text('Une seule fois'),
                      ),
                    ],
                    selected: {_daily},
                    onSelectionChanged: (s) => setState(() => _daily = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (!_daily)
                    LabeledField(
                      label: 'Date',
                      hint: '',
                      controller: _dateText,
                      readOnly: true,
                      onTap: _pickDate,
                      suffix: const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                      ),
                    ),
                  const _Label('Type'),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_type),
                    initialValue: _type,
                    items: [
                      for (final type in mealTypes)
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
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Aliment',
                    hint: 'Croquettes… ou cherche un produit 🔍',
                    controller: _food,
                    onChanged: (v) {
                      if (_product != null && v != _product!.displayName) {
                        _unlinkProduct();
                      }
                    },
                    suffix: IconButton(
                      tooltip: 'Chercher dans Open Pet Food Facts',
                      icon: const Icon(Icons.manage_search_rounded),
                      onPressed: _pickProduct,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  if (_product != null) _productCard(_product!),
                  LabeledField(
                    label: 'Quantité',
                    hint: '100 g',
                    controller: _qty,
                  ),
                  LabeledField(
                    label: 'Calories',
                    hint: '300',
                    controller: _cal,
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v?.trim() ?? '') == null
                        ? 'Nombre entier requis'
                        : null,
                  ),
                  if (_kcal100 != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        g == null
                            ? 'Indique la quantité en g ou kg pour calculer '
                                  'les calories (${_kcal100!.round()} kcal/100 g).'
                            : 'Calculé : $g g × ${_kcal100!.round()} kcal/100 g',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  LabeledField(
                    label: 'Heure',
                    hint: '08:00',
                    controller: _time,
                    validator: (v) =>
                        RegExp(
                          r'^([01]?\d|2[0-3])[:hH][0-5]\d$',
                        ).hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Format HH:MM',
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _isEdit
                          ? 'Enregistrer les modifications'
                          : 'Enregistrer le repas',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(PetFoodProduct p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ProductThumb(url: p.imageUrl, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produit Open Pet Food Facts',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    kcalLabel(p),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Détails',
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                builder: (_) => ProductDetailSheet(
                  product: p,
                  pet: _currentPet!,
                  vetItems: _vetItems,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Retirer le produit',
              icon: const Icon(Icons.link_off_rounded),
              onPressed: _unlinkProduct,
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
