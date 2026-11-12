import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_stock_repository.dart';
import 'package:flutter_example/modules/alimentation/repositories/weight_repository.dart';
import 'package:flutter_example/modules/alimentation/screens/add_meal_screen.dart';
import 'package:flutter_example/modules/alimentation/screens/can_eat_screen.dart';
import 'package:flutter_example/modules/alimentation/screens/meal_history_screen.dart';
import 'package:flutter_example/modules/alimentation/services/meal_history.dart';
import 'package:flutter_example/modules/alimentation/widgets/food_stock_tab.dart';
import 'package:flutter_example/modules/alimentation/widgets/weight_tab.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen>
    with SingleTickerProviderStateMixin {
  static const _weightTab = 3;
  static const _stockTab = 4;

  final _petsRepo = PetRepository();
  final _foodRepo = FoodRepository();
  final _weightRepo = WeightRepository();
  final _stockRepo = FoodStockRepository();
  late final TabController _tabs;
  List<Pet> _pets = [];
  List<WeightLog> _weights = [];
  List<FoodStock> _stocks = [];
  List<Meal> _meals = [];
  List<MealEntry> _dayEntries = [];
  List<FoodItem> _allowed = [];
  List<FoodItem> _forbidden = [];
  Diet? _diet;
  DateTime _day = dayOnly(DateTime.now());
  int _pet = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging && mounted) setState(() {});
      });
    _load();
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return;
    final pets = await _petsRepo.getByOwner(ownerId);
    if (!mounted) return;
    setState(() {
      _pets = pets;
      if (_pet >= _pets.length) _pet = 0;
      _loading = false;
    });
    await _loadFood();
  }

  Future<void> _loadFood() async {
    if (_pets.isEmpty) {
      setState(() {
        _meals = [];
        _dayEntries = [];
        _allowed = [];
        _forbidden = [];
        _diet = null;
        _weights = [];
        _stocks = [];
      });
      return;
    }
    final id = _pets[_pet].id!;
    final meals = await _foodRepo.getMeals(id);
    final day = await _foodRepo.getDay(id, _day);
    final a = await _foodRepo.getFoodItems(id, allowed: true);
    final f = await _foodRepo.getFoodItems(id, allowed: false);
    final diet = await _foodRepo.getDiet(id);
    final weights = await _weightRepo.getLogs(id);
    final stocks = await _stockRepo.getStocks(id);
    if (mounted) {
      setState(() {
        _meals = meals;
        _dayEntries = day;
        _allowed = a;
        _forbidden = f;
        _diet = diet;
        _weights = weights;
        _stocks = stocks;
      });
    }
  }

  Future<void> _setDay(DateTime day) async {
    setState(() => _day = dayOnly(day));
    await _loadFood();
  }

  /// Historique : un jour touché dans les résultats s'ouvre ici.
  Future<void> _openHistory() async {
    final jump = await Navigator.push<(int, DateTime)>(
      context,
      MaterialPageRoute(
        builder: (_) => MealHistoryScreen(pets: _pets, initialIndex: _pet),
      ),
    );
    if (jump == null || !mounted) return;
    final (petIndex, day) = jump;
    setState(() {
      _pet = petIndex;
      _day = dayOnly(day);
    });
    _tabs.animateTo(0);
    await _loadFood();
  }

  bool get _isFuture => _day.isAfter(dayOnly(DateTime.now()));

  Future<void> _openMealForm({Meal? meal}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMealScreen(
          meal: meal,
          initialDate: _day,
          initialPetId: _pets.isEmpty ? null : _pets[_pet].id,
        ),
      ),
    );
    await _loadFood();
  }

  /// Bouton flottant selon l'onglet : repas, pesée ou sac (rien sur les
  /// onglets en lecture seule Autorisés / Interdits).
  Widget? _fab() {
    final pet = _pets.isEmpty ? null : _pets[_pet];
    switch (_tabs.index) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'fab_food',
          onPressed: () => _openMealForm(),
          icon: const Icon(Icons.add),
          label: const Text('Repas'),
        );
      case _weightTab when pet != null:
        return FloatingActionButton.extended(
          heroTag: 'fab_weight',
          onPressed: () async {
            if (await showWeightSheet(context, pet: pet)) await _loadFood();
          },
          icon: const Icon(Icons.monitor_weight_outlined),
          label: const Text('Pesée'),
        );
      case _stockTab when pet != null:
        return FloatingActionButton.extended(
          heroTag: 'fab_stock',
          onPressed: () async {
            if (await showFoodStockSheet(
              context,
              pet: pet,
              meals: _dailyMeals,
            )) {
              await _loadFood();
            }
          },
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Sac'),
        );
      default:
        return null;
    }
  }

  List<Meal> get _dailyMeals => _meals.where((m) => m.isDaily).toList();

  Widget _needsPet(Widget Function(Pet pet) builder) => _pets.isEmpty
      ? const Center(child: Text('Ajoute d’abord un animal'))
      : builder(_pets[_pet]);

  int get _kcal =>
      _dayEntries.where((e) => e.done).fold(0, (s, e) => s + e.calories);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lowStocks = _stocks.where((st) => st.isLow()).toList();
    final doneCount = _dayEntries.where((e) => e.done).length;
    return Scaffold(
      floatingActionButton: _fab(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alimentation',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Peut-il manger ça ?'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CanEatScreen(pets: _pets, initialIndex: _pet),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PetSelector(
              pets: _pets,
              selected: _pet,
              onChanged: (i) async {
                setState(() => _pet = i);
                await _loadFood();
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppCard(
                color: AppColors.food,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${frDayLabel(_day)} · $_kcal kcal · '
                      '$doneCount/${_dayEntries.length} repas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _diet == null
                          ? 'Régime : en attente de prescription vétérinaire'
                          : 'Régime véto : ${_diet!.dietType} · ${_diet!.goal} · ${_diet!.mealsPerDay} repas/j',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                    if (lowStocks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Stock bas : ${lowStocks.map((st) => st.name).join(', ')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_diet != null && _diet!.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _diet!.notes,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Repas'),
                Tab(text: 'Autorisés'),
                Tab(text: 'Interdits'),
                Tab(text: 'Poids'),
                Tab(text: 'Stock'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _mealsTab(),
                  _foodGrid(_allowed, true),
                  _foodGrid(_forbidden, false),
                  _needsPet(
                    (pet) => WeightTab(
                      pet: pet,
                      logs: _weights,
                      diet: _diet,
                      onChanged: _loadFood,
                    ),
                  ),
                  _needsPet(
                    (pet) => FoodStockTab(
                      pet: pet,
                      stocks: _stocks,
                      meals: _dailyMeals,
                      onChanged: _loadFood,
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

  Widget _dayNavigator() {
    final today = dayOnly(DateTime.now());
    return Row(
      children: [
        IconButton(
          tooltip: 'Jour précédent',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => _setDay(_day.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: today.add(const Duration(days: 365)),
                initialDate: _day,
              );
              if (d != null) await _setDay(d);
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(
              frDayLabel(_day, long: true),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (_day != today)
          TextButton(
            onPressed: () => _setDay(today),
            child: const Text("Aujourd'hui"),
          ),
        IconButton(
          tooltip: 'Jour suivant',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => _setDay(_day.add(const Duration(days: 1))),
        ),
      ],
    );
  }

  Widget _mealsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        _dayNavigator(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openHistory,
            icon: const Icon(Icons.manage_search_rounded, size: 20),
            label: const Text('Rechercher dans l’historique'),
          ),
        ),
        if (_dayEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun repas ce jour-là. Ajoute un repas quotidien ou ponctuel. '
              'Le régime et les aliments autorisés/interdits sont prescrits '
              'par le vétérinaire.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final e in _dayEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _mealTile(e),
          ),
      ],
    );
  }

  Widget _mealTile(MealEntry e) {
    final meal = e.meal;
    final tag = meal == null
        ? 'repas supprimé'
        : (meal.isDaily ? 'tous les jours' : 'ponctuel');
    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 8),
        leading: Icon(
          meal?.icon ?? Icons.restaurant_rounded,
          color: AppColors.food,
        ),
        title: Text(e.name),
        subtitle: Text(
          '${e.time} · ${e.food} · ${e.quantity} · ${e.calories} kcal\n$tag',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meal != null)
              PopupMenuButton<String>(
                onSelected: (v) =>
                    v == 'edit' ? _openMealForm(meal: meal) : _delete(meal),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            IconButton(
              tooltip: _isFuture
                  ? 'Impossible de cocher un jour futur'
                  : 'Fait / pas fait',
              icon: Icon(
                e.done ? Icons.check_circle : Icons.circle_outlined,
                color: e.done ? AppColors.health : AppColors.textSecondary,
              ),
              onPressed: _isFuture ? null : () => _toggle(e),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(MealEntry e) async {
    if (e.meal != null) {
      await _foodRepo.setDone(e.meal!, _day, !e.done);
    } else if (e.log?.id != null) {
      await _foodRepo.deleteLog(e.log!.id!);
    }
    await _loadFood();
  }

  Future<void> _delete(Meal m) async {
    if (m.id == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer ce repas ?',
      message: '${m.name} — les jours déjà cochés restent dans l’historique.',
      confirmLabel: 'Supprimer',
    );
    if (!ok) return;
    await _foodRepo.deleteMeal(m.id!);
    await LocalNotifications.instance.cancel(LocalNotifications.mealId(m.id!));
    await _loadFood();
  }

  Widget _foodGrid(List<FoodItem> items, bool ok) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          ok
              ? 'Aucun aliment autorisé (prescrit par le véto)'
              : 'Aucun aliment interdit (prescrit par le véto)',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final f in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: ListTile(
                leading: Text(f.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(f.name),
                subtitle: Text(f.note),
                trailing: Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: ok ? AppColors.health : AppColors.reminder,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
