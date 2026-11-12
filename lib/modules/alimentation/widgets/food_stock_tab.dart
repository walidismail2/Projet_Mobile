import 'package:flutter/material.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_stock_repository.dart';

/// Ration quotidienne suggérée = somme des quantités en grammes des repas.
/// Null si aucune quantité de repas n'est exprimée en g / kg.
int? suggestedDailyGrams(List<Meal> meals) {
  final grams = meals.map((m) => parseGrams(m.quantity)).whereType<int>();
  if (grams.isEmpty) return null;
  return grams.fold<int>(0, (a, b) => a + b);
}

/// Onglet « Stock » : sacs de nourriture et jours restants estimés.
class FoodStockTab extends StatelessWidget {
  final Pet pet;
  final List<FoodStock> stocks;
  final List<Meal> meals;
  final VoidCallback onChanged;

  const FoodStockTab({
    super.key,
    required this.pet,
    required this.stocks,
    required this.meals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Ajoute le sac de nourriture de ${pet.name} : '
                'PetCare estime quand il sera vide et te prévient avant.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  if (await showFoodStockSheet(
                    context,
                    pet: pet,
                    meals: meals,
                  )) {
                    onChanged();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un sac'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final s in stocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StockCard(
              stock: s,
              pet: pet,
              meals: meals,
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  final FoodStock stock;
  final Pet pet;
  final List<Meal> meals;
  final VoidCallback onChanged;

  const _StockCard({
    required this.stock,
    required this.pet,
    required this.meals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final days = stock.daysLeft();
    final ratio = stock.remainingRatio();
    final low = stock.isLow();
    final empty = stock.remainingGrams() == 0;
    final barColor = low ? AppColors.reminder : AppColors.health;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥫', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stock.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (low)
                StatusPill(
                  empty ? 'Épuisé' : 'Stock bas',
                  AppColors.reminder,
                  icon: Icons.warning_amber_rounded,
                ),
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(context, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              color: barColor,
              backgroundColor: AppColors.border,
              semanticsLabel: 'Stock restant',
              semanticsValue: '${(ratio * 100).round()} %',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            empty
                ? 'Sac vide depuis le ${formatFrDate(stock.runOutDate)}'
                : '≈ ${_mass(stock.remainingGrams())} restants · '
                      '$days jour${days > 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_mass(stock.bagGrams)} ouvert le ${formatFrDate(stock.openedDate)}'
            ' · ${stock.dailyGrams} g/jour'
            '${empty ? '' : ' · vide vers le ${formatFrDate(stock.runOutDate)}'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _newBag(context),
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Nouveau sac ouvert'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String action) async {
    if (action == 'edit') {
      if (await showFoodStockSheet(
        context,
        pet: pet,
        meals: meals,
        existing: stock,
      )) {
        onChanged();
      }
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer ce stock ?',
      message: stock.name,
      confirmLabel: 'Supprimer',
    );
    if (!ok || stock.id == null) return;
    await LocalNotifications.instance.cancel(
      LocalNotifications.stockId(stock.id!),
    );
    await FoodStockRepository().delete(stock.id!);
    onChanged();
  }

  /// Même produit, nouveau sac plein ouvert aujourd'hui.
  Future<void> _newBag(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Nouveau sac ouvert ?',
      message:
          '${stock.name} · ${_mass(stock.bagGrams)} — le compteur repart d’aujourd’hui.',
      confirmLabel: 'Confirmer',
      color: AppColors.health,
      icon: Icons.autorenew_rounded,
    );
    if (!ok) return;
    final refreshed = stock.copyWith(openedDate: DateTime.now());
    await FoodStockRepository().update(refreshed);
    await LocalNotifications.instance.scheduleFoodStock(
      refreshed,
      petName: pet.name,
    );
    if (context.mounted) showSuccessSnack(context, 'Stock réinitialisé');
    onChanged();
  }
}

String _mass(int grams) => grams >= 1000
    ? '${(grams / 1000).toStringAsFixed(grams % 1000 == 0 ? 0 : 1).replaceAll('.', ',')} kg'
    : '$grams g';

/// Ajout / édition d'un sac. Renvoie `true` si enregistré.
Future<bool> showFoodStockSheet(
  BuildContext context, {
  required Pet pet,
  required List<Meal> meals,
  FoodStock? existing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _StockSheet(pet: pet, meals: meals, existing: existing),
  );
  return saved == true;
}

class _StockSheet extends StatefulWidget {
  final Pet pet;
  final List<Meal> meals;
  final FoodStock? existing;

  const _StockSheet({required this.pet, required this.meals, this.existing});

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  static const _alertChoices = [1, 2, 3, 5, 7];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bagKg;
  late final TextEditingController _daily;
  late final TextEditingController _dateText;
  late DateTime _opened;
  late int _alertDays;
  int? _suggested;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _suggested = suggestedDailyGrams(widget.meals);
    final mealFood = widget.meals.isNotEmpty
        ? widget.meals.first.food
        : 'Croquettes';
    _name = TextEditingController(text: e?.name ?? mealFood);
    _bagKg = TextEditingController(
      text: e == null
          ? ''
          : (e.bagGrams / 1000).toString().replaceAll('.', ','),
    );
    _daily = TextEditingController(
      text: '${e?.dailyGrams ?? _suggested ?? ''}',
    );
    _opened = e?.openedDate ?? DateTime.now();
    _dateText = TextEditingController(text: formatFrDate(_opened));
    _alertDays = e?.alertDays ?? 3;
  }

  @override
  void dispose() {
    _name.dispose();
    _bagKg.dispose();
    _daily.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDate: _opened.isAfter(DateTime.now()) ? DateTime.now() : _opened,
    );
    if (d == null) return;
    setState(() {
      _opened = d;
      _dateText.text = formatFrDate(d);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = FoodStockRepository();
    var stock = FoodStock(
      id: widget.existing?.id,
      petId: widget.pet.id!,
      name: _name.text.trim(),
      bagGrams: (parseDecimal(_bagKg.text)! * 1000).round(),
      dailyGrams: int.parse(_daily.text.trim()),
      openedDate: _opened,
      alertDays: _alertDays,
    );
    if (stock.id == null) {
      stock = stock.copyWith(id: await repo.insert(stock));
    } else {
      await repo.update(stock);
    }
    await LocalNotifications.instance.scheduleFoodStock(
      stock,
      petName: widget.pet.name,
      recordInApp: true,
    );
    if (!mounted) return;
    showSuccessSnack(
      context,
      stock.isLow()
          ? 'Stock enregistré · déjà bas !'
          : 'Alerte prévue le ${formatFrDate(stock.alertDate)}',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? 'Nouveau sac · ${widget.pet.name}'
                    : 'Modifier le stock',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Produit',
                hint: 'Croquettes adulte…',
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              LabeledField(
                label: 'Taille du sac (kg)',
                hint: '12',
                controller: _bagKg,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final kg = parseDecimal(v ?? '');
                  if (kg == null || kg <= 0 || kg > 100) {
                    return 'Taille invalide (0 – 100 kg)';
                  }
                  return null;
                },
              ),
              LabeledField(
                label: 'Ration par jour (g)',
                hint: '300',
                controller: _daily,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final g = int.tryParse(v?.trim() ?? '');
                  if (g == null || g <= 0 || g > 5000) {
                    return 'Ration invalide (1 – 5000 g)';
                  }
                  return null;
                },
              ),
              if (_suggested != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Suggéré d’après les repas : $_suggested g/jour',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              LabeledField(
                label: 'Ouvert le',
                hint: '',
                controller: _dateText,
                readOnly: true,
                onTap: _pickDate,
                suffix: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              const Text(
                'Me prévenir',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _alertDays,
                items: [
                  for (final d in _alertChoices)
                    DropdownMenuItem(
                      value: d,
                      child: Text('$d jour${d > 1 ? 's' : ''} avant la fin'),
                    ),
                ],
                onChanged: (v) => setState(() => _alertDays = v ?? 3),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
