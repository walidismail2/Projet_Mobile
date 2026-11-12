import 'package:flutter/material.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/screens/add_meal_screen.dart'
    show mealTypes;
import 'package:flutter_example/modules/alimentation/services/meal_history.dart';

/// Recherche dans l'historique des repas cochés « fait » (`meal_logs`) :
/// texte (aliment / type de repas), période, type de repas, + totaux.
///
/// Toucher un jour renvoie `(index animal, jour)` à l'écran Alimentation,
/// qui affiche alors ce jour-là.
class MealHistoryScreen extends StatefulWidget {
  final List<Pet> pets;
  final int initialIndex;

  const MealHistoryScreen({
    super.key,
    required this.pets,
    this.initialIndex = 0,
  });

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final _repo = FoodRepository();
  final _query = TextEditingController();
  late int _pet;
  HistoryPeriod _period = HistoryPeriod.thisMonth;
  DateTimeRange? _custom;
  String? _mealType;
  List<MealLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pet = widget.pets.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.pets.length - 1);
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  (DateTime?, DateTime?) get _range => _period == HistoryPeriod.custom
      ? (_custom?.start, _custom?.end)
      : _period.range(DateTime.now());

  Future<void> _load() async {
    final id = widget.pets.isEmpty ? null : widget.pets[_pet].id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final (from, to) = _range;
    final logs = await _repo.getLogs(
      id,
      from: from,
      to: to,
      mealName: _mealType,
    );
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _pickPeriod(HistoryPeriod p) async {
    if (p == HistoryPeriod.custom) {
      final today = dayOnly(DateTime.now());
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: today,
        initialDateRange:
            _custom ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 13)),
              end: today,
            ),
      );
      if (r == null) return;
      _custom = r;
    }
    setState(() => _period = p);
    await _load();
  }

  String _periodLabel(HistoryPeriod p) {
    if (p != HistoryPeriod.custom || _custom == null) return p.label;
    String short(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${short(_custom!.start)} – ${short(_custom!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final results = filterLogsByText(_logs, _query.text);
    final summary = MealHistorySummary.of(results);
    final groups = groupLogsByDay(results);
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des repas')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          PetSelector(
            pets: widget.pets,
            selected: _pet,
            onChanged: (i) {
              setState(() => _pet = i);
              _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Aliment ou repas : Royal Canin, dîner…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
            ),
          ),
          _chips([
            for (final p in HistoryPeriod.values)
              ChoiceChip(
                label: Text(_periodLabel(p)),
                selected: _period == p,
                onSelected: (_) => _pickPeriod(p),
              ),
          ]),
          _chips([
            ChoiceChip(
              label: const Text('Tous les repas'),
              selected: _mealType == null,
              onSelected: (_) {
                setState(() => _mealType = null);
                _load();
              },
            ),
            for (final t in mealTypes)
              ChoiceChip(
                label: Text(t),
                selected: _mealType == t,
                onSelected: (_) {
                  setState(() => _mealType = t);
                  _load();
                },
              ),
          ]),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (results.isEmpty)
            _empty()
          else ...[
            _summaryCard(summary),
            for (final (day, logs) in groups) _dayGroup(day, logs),
          ],
        ],
      ),
    );
  }

  Widget _chips(List<Widget> chips) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Wrap(spacing: 8, runSpacing: 0, children: chips),
  );

  Widget _empty() {
    final filtered = _query.text.trim().isNotEmpty || _mealType != null;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'Aucun repas ne correspond à cette recherche sur la période.'
                : 'Aucun repas coché sur cette période. L’historique se '
                      'remplit quand tu coches les repas dans l’onglet Repas.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(MealHistorySummary s) {
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.w700);
    final soft = TextStyle(
      color: Colors.white.withValues(alpha: 0.92),
      fontSize: 13,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AppCard(
        color: AppColors.food,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.meals} repas · ${_thousands(s.totalKcal)} kcal',
              style: white.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Sur ${s.days} jour${s.days > 1 ? 's' : ''} · '
              '≈ ${_thousands(s.kcalPerDay)} kcal / jour',
              style: soft,
            ),
            if (s.grams > 0)
              Text(
                '≈ ${_mass(s.grams)} mangés'
                '${s.mealsWithoutGrams > 0 ? ' (+ ${s.mealsWithoutGrams} '
                          'repas sans quantité en g)' : ''}',
                style: soft,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dayGroup(DateTime day, List<MealLog> logs) {
    final kcal = logs.fold(0, (s, l) => s + l.calories);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context, (_pet, day)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      frDayLabel(day, long: true),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$kcal kcal',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          for (final l in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.food,
                  ),
                  title: Text(l.food),
                  subtitle: Text('${l.time} · ${l.mealName} · ${l.quantity}'),
                  trailing: Text(
                    '${l.calories} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

String _mass(int grams) => grams >= 1000
    ? '${(grams / 1000).toStringAsFixed(1).replaceAll('.', ',')} kg'
    : '$grams g';
