import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/services/meal_history.dart';

MealLog _log(String food, DateTime date,
        {String meal = 'Dîner',
        String time = '19:00',
        String qty = '100 g',
        int kcal = 350}) =>
    MealLog(
      petId: 1,
      date: date,
      mealName: meal,
      time: time,
      food: food,
      quantity: qty,
      calories: kcal,
    );

void main() {
  final logs = [
    _log('Royal Canin · Puppy Food', DateTime(2026, 11, 12),
        meal: 'Petit-déjeuner', time: '08:00', qty: '150 g', kcal: 548),
    _log('Royal Canin · Puppy Food', DateTime(2026, 11, 11), qty: '0,15 kg'),
    _log('Pâtée poulet', DateTime(2026, 11, 11),
        meal: 'Collation', time: '16:00', qty: '1 boîte', kcal: 90),
    _log('Riz et carottes', DateTime(2026, 10, 30), kcal: 200),
  ];

  group('filterLogsByText', () {
    test('every word must match, accents and case ignored', () {
      expect(filterLogsByText(logs, 'royal canin').length, 2);
      expect(filterLogsByText(logs, 'ROYAL puppy').length, 2);
      expect(filterLogsByText(logs, 'patee').single.food, 'Pâtée poulet');
      expect(filterLogsByText(logs, 'royal riz'), isEmpty);
    });

    test('also searches the meal type', () {
      expect(filterLogsByText(logs, 'collation').single.food, 'Pâtée poulet');
    });

    test('empty query keeps everything', () {
      expect(filterLogsByText(logs, '  ').length, 4);
    });
  });

  group('HistoryPeriod.range', () {
    final now = DateTime(2026, 11, 12, 18, 30);

    test('rolling windows include today', () {
      expect(HistoryPeriod.last7.range(now),
          (DateTime(2026, 11, 6), DateTime(2026, 11, 12)));
      expect(HistoryPeriod.last30.range(now).$1, DateTime(2026, 10, 14));
    });

    test('calendar months', () {
      expect(HistoryPeriod.thisMonth.range(now),
          (DateTime(2026, 11, 1), DateTime(2026, 11, 12)));
      expect(HistoryPeriod.lastMonth.range(now),
          (DateTime(2026, 10, 1), DateTime(2026, 10, 31)));
    });

    test('last month from January is December of last year', () {
      expect(HistoryPeriod.lastMonth.range(DateTime(2027, 1, 5)),
          (DateTime(2026, 12, 1), DateTime(2026, 12, 31)));
    });

    test('all has no limits', () {
      expect(HistoryPeriod.all.range(now), (null, null));
    });
  });

  test('summary totals meals, kcal, days and grams', () {
    final s = MealHistorySummary.of(logs);
    expect(s.meals, 4);
    expect(s.totalKcal, 548 + 350 + 90 + 200);
    expect(s.days, 3);
    expect(s.grams, 150 + 150 + 100);
    expect(s.mealsWithoutGrams, 1);
    expect(s.kcalPerDay, ((548 + 350 + 90 + 200) / 3).round());
    expect(MealHistorySummary.of(const []).kcalPerDay, 0);
  });

  test('groups by day, newest first, meals sorted by time', () {
    final g = groupLogsByDay(logs);
    expect(g.map((e) => e.$1), [
      DateTime(2026, 11, 12),
      DateTime(2026, 11, 11),
      DateTime(2026, 10, 30),
    ]);
    expect(g[1].$2.map((l) => l.time), ['16:00', '19:00']);
  });
}
