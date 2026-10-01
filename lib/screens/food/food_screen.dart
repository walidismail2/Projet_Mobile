import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'add_meal_screen.dart';
import 'diet_form_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  int _pet = 0;
  late final List<bool> _done = MockData.meals.map((m) => m.done).toList();

  @override
  Widget build(BuildContext context) {
    final doneCount = _done.where((d) => d).length;
    final calories = [
      for (var i = 0; i < MockData.meals.length; i++)
        if (_done[i]) MockData.meals[i].calories
    ].fold(0, (a, b) => a + b);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMealScreen()),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un repas',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Text('Alimentation',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    PetSelector(
                      selected: _pet,
                      onChanged: (i) => setState(() => _pet = i),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _DailyProgress(
                        calories: calories,
                        doneCount: doneCount,
                        total: MockData.meals.length,
                      ),
                    ),
                  ],
                ),
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: PinnedTabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      Tab(text: 'Aujourd\'hui'),
                      Tab(text: 'Régime'),
                      Tab(text: 'Aliments'),
                      Tab(text: 'Historique'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _TodayTab(
                  done: _done,
                  onToggle: (i) => setState(() => _done[i] = !_done[i]),
                ),
                const _DietTab(),
                const _FoodsTab(),
                const _HistoryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyProgress extends StatelessWidget {
  final int calories;
  final int doneCount;
  final int total;

  const _DailyProgress({
    required this.calories,
    required this.doneCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    const target = 1120;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC04D), AppColors.food],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: calories / target,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  constraints:
                      const BoxConstraints.tightFor(width: 90, height: 90),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$calories',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const Text('kcal',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Objectif du jour',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text('$calories / $target kcal',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _MiniStat(
                        icon: Icons.restaurant_rounded,
                        value: '$doneCount/$total',
                        label: 'repas'),
                    const _MiniStat(
                        icon: Icons.water_drop_rounded,
                        value: '0,8 L',
                        label: 'eau'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text('$value $label',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  final List<bool> done;
  final ValueChanged<int> onToggle;

  const _TodayTab({required this.done, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: MockData.meals.length,
      itemBuilder: (context, i) {
        final m = MockData.meals[i];
        final isDone = done[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => onToggle(i),
            child: Row(
              children: [
                IconBadge(m.icon, AppColors.food),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(m.name,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                          const SizedBox(width: 8),
                          Text(m.time,
                              style: const TextStyle(
                                  color: AppColors.food,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${m.food} · ${m.quantity}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text('${m.calories} kcal',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.health : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? AppColors.health : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DietTab extends StatelessWidget {
  const _DietTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        SectionHeader(
          'Régime alimentaire',
          action: 'Modifier',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DietFormScreen()),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const Column(
            children: [
              InfoRow(Icons.set_meal_rounded, 'Type', 'Croquettes + pâtée'),
              Divider(height: 1),
              InfoRow(Icons.shopping_bag_rounded, 'Marque',
                  'Royal Canin Golden'),
              Divider(height: 1),
              InfoRow(Icons.schedule_rounded, 'Repas par jour', '3 + 1 friandise'),
              Divider(height: 1),
              InfoRow(Icons.scale_rounded, 'Ration quotidienne', '350 g'),
              Divider(height: 1),
              InfoRow(Icons.local_fire_department_rounded, 'Apport calorique',
                  '1 120 kcal'),
              Divider(height: 1),
              InfoRow(Icons.water_drop_rounded, 'Eau recommandée', '1,4 L'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader('Répartition des quantités'),
        AppCard(
          child: Column(
            children: [
              for (final (label, grams, ratio) in const [
                ('Petit-déjeuner', '120 g', 0.34),
                ('Déjeuner', '100 g', 0.29),
                ('Dîner', '130 g', 0.37),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy)),
                          const Spacer(),
                          Text(grams,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.food)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor:
                              AppColors.food.withValues(alpha: 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.food),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.vet.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.vet),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Régime recommandé par Dr. Martin pour un chien adulte de 28 kg, activité modérée.',
                  style: TextStyle(color: AppColors.navy, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodsTab extends StatelessWidget {
  const _FoodsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _FoodSection(
          title: 'Aliments autorisés',
          color: AppColors.health,
          icon: Icons.check_circle_rounded,
          items: MockData.allowedFoods,
        ),
        const SizedBox(height: 24),
        _FoodSection(
          title: 'Aliments interdits',
          color: AppColors.reminder,
          icon: Icons.block_rounded,
          items: MockData.forbiddenFoods,
        ),
      ],
    );
  }
}

class _FoodSection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<FoodItem> items;

  const _FoodSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
              ),
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final f in items)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  title: Text(f.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.navy)),
                  subtitle: Text(f.note),
                  trailing: Icon(icon, color: color, size: 20),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Mardi 29 sept.', 4, 4, 1120),
      ('Lundi 28 sept.', 3, 4, 1050),
      ('Dimanche 27 sept.', 4, 4, 1140),
      ('Samedi 26 sept.', 2, 4, 640),
      ('Vendredi 25 sept.', 4, 4, 1100),
      ('Jeudi 24 sept.', 3, 4, 980),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cette semaine',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (d, v) in const [
                      ('L', 0.85),
                      ('M', 0.95),
                      ('M', 0.7),
                      ('J', 0.88),
                      ('V', 0.98),
                      ('S', 0.57),
                      ('D', 1.0),
                    ])
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 80 * v,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: v >= 0.85
                                    ? AppColors.food
                                    : AppColors.food.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(d,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (day, done, total, kcal) in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconBadge(
                    done == total
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    done == total ? AppColors.health : AppColors.food,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy)),
                        Text('$done/$total repas · $kcal kcal',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Text('${(done / total * 100).round()} %',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: done == total
                              ? AppColors.health
                              : AppColors.food)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
