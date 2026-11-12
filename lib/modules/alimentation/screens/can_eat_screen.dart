import 'package:flutter/material.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/services/food_safety_service.dart';

/// « Peut-il manger ça ? » — recherche hors ligne : prescription du véto +
/// base locale d'aliments toxiques / à éviter / sans danger.
class CanEatScreen extends StatefulWidget {
  final List<Pet> pets;
  final int initialIndex;

  const CanEatScreen({super.key, required this.pets, this.initialIndex = 0});

  @override
  State<CanEatScreen> createState() => _CanEatScreenState();
}

class _CanEatScreenState extends State<CanEatScreen> {
  static const _suggestions = [
    'Chocolat',
    'Raisin',
    'Oignon',
    'Fromage',
    'Os cuit',
    'Carotte',
    'Avocat',
    'Lait',
    'Pomme',
    'Riz',
  ];

  final _query = TextEditingController();
  final _repo = FoodRepository();
  late int _pet;
  List<FoodItem> _vetItems = [];
  List<SafetyResult> _results = [];

  Pet? get _currentPet => widget.pets.isEmpty ? null : widget.pets[_pet];
  String get _species => _currentPet?.species ?? '';

  @override
  void initState() {
    super.initState();
    _pet = widget.initialIndex.clamp(
      0,
      widget.pets.isEmpty ? 0 : widget.pets.length - 1,
    );
    _loadVetItems();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadVetItems() async {
    final id = _currentPet?.id;
    if (id == null) return;
    final a = await _repo.getFoodItems(id, allowed: true);
    final f = await _repo.getFoodItems(id, allowed: false);
    if (!mounted) return;
    setState(() => _vetItems = [...a, ...f]);
    _search();
  }

  void _search() {
    setState(() {
      _results = FoodSafetyService.lookup(
        _query.text,
        species: _species,
        vetItems: _vetItems,
      );
    });
  }

  void _pick(String s) {
    _query.text = s;
    _query.selection = TextSelection.collapsed(offset: s.length);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim();
    final petName = _currentPet?.name ?? 'mon animal';
    return Scaffold(
      appBar: AppBar(title: const Text('Peut-il manger ça ?')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          PetSelector(
            pets: widget.pets,
            selected: _pet,
            onChanged: (i) {
              setState(() => _pet = i);
              _loadVetItems();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: '$petName peut-il manger… ?',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _pick(''),
                      ),
              ),
            ),
          ),
          if (q.length < 2) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in _suggestions)
                    ActionChip(label: Text(s), onPressed: () => _pick(s)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Fonctionne hors ligne. Combine la prescription de ton '
                'vétérinaire et une base d’aliments toxiques ou à éviter '
                'pour les chiens et les chats.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ] else if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Row(
                  children: [
                    const Text('❓', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '« $q » n’est pas dans notre base. En cas de doute, '
                        'ne le donne pas et demande à ton vétérinaire.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final r in _results)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _ResultCard(r),
              ),
          if (_species != 'Chien' && _species != 'Chat' && _currentPet != null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La base couvre les chiens et les chats : pour une autre '
                'espèce, le niveau le plus prudent des deux est affiché.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Text(
              'Ingestion d’un aliment toxique ? Contacte immédiatement ton '
              'vétérinaire ou un centre antipoison vétérinaire, même sans '
              'symptôme.',
              style: TextStyle(
                color: AppColors.reminder,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SafetyResult r;
  const _ResultCard(this.r);

  Color get _color => switch (r.level) {
    SafetyLevel.toxic || SafetyLevel.vetForbidden => AppColors.reminder,
    SafetyLevel.caution => AppColors.food,
    SafetyLevel.vetAllowed || SafetyLevel.safe => AppColors.health,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill('${r.level.icon} ${r.level.label}', _color),
                const SizedBox(height: 6),
                Text(
                  r.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(r.reason),
                const SizedBox(height: 6),
                Text(
                  'Source : ${r.source}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
