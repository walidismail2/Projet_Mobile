import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/screens/add_meal_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final _petsRepo = PetRepository();
  final _foodRepo = FoodRepository();
  List<Pet> _pets = [];
  List<Meal> _meals = [];
  List<FoodItem> _allowed = [];
  List<FoodItem> _forbidden = [];
  Diet? _diet;
  int _pet = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AppRefresh.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onDataChanged);
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
        _allowed = [];
        _forbidden = [];
        _diet = null;
      });
      return;
    }
    final id = _pets[_pet].id!;
    final meals = await _foodRepo.getMeals(id);
    final a =
        await _foodRepo.getFoodItemsForCurrentOwner(id, allowed: true);
    final f =
        await _foodRepo.getFoodItemsForCurrentOwner(id, allowed: false);
    final diet = await _foodRepo.getDietForCurrentOwner(id);
    if (mounted) {
      setState(() {
        _meals = meals;
        _allowed = a;
        _forbidden = f;
        _diet = diet;
      });
    }
  }

  int get _kcal =>
      _meals.where((m) => m.done).fold(0, (s, m) => s + m.calories);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_food',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMealScreen()),
            );
            await _loadFood();
          },
          icon: const Icon(Icons.add),
          label: const Text('Repas'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Alimentation',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              PetSelector(
                pets: _pets,
                selected: _pet,
                onChanged: (i) async {
                  setState(() => _pet = i);
                  await _loadFood();
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppCard(
                  color: AppColors.food,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_kcal kcal · ${_meals.where((m) => m.done).length}/${_meals.length} repas',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
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
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: "Aujourd'hui"),
                  Tab(text: 'Autorisés'),
                  Tab(text: 'Interdits'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_meals.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Tu suis les repas ici. Le régime et les aliments autorisés/interdits sont prescrits par le vétérinaire.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final m in _meals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: ListTile(
                                leading: Icon(m.icon, color: AppColors.food),
                                title: Text(m.name),
                                subtitle: Text(
                                    '${m.time} · ${m.food} · ${m.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Modifier',
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 20),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddMealScreen(meal: m),
                                          ),
                                        );
                                        await _loadFood();
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      onPressed: () async {
                                        if (m.id == null) return;
                                        final ok = await showConfirmDialog(
                                          context,
                                          title: 'Supprimer ce repas ?',
                                          message: m.name,
                                          confirmLabel: 'Supprimer',
                                        );
                                        if (!ok) return;
                                        await _foodRepo.deleteMeal(m.id!);
                                        await LocalNotifications.instance.cancel(
                                            LocalNotifications.mealId(m.id!));
                                        await _loadFood();
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Fait / pas fait',
                                      icon: Icon(
                                        m.done
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: m.done
                                            ? AppColors.health
                                            : AppColors.textSecondary,
                                      ),
                                      onPressed: () async {
                                        if (m.id == null) return;
                                        await _foodRepo.setMealDone(
                                            m.id!, !m.done);
                                        await _loadFood();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    _foodGrid(_allowed, true),
                    _foodGrid(_forbidden, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
