import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/widgets/food_stock_tab.dart';

Meal _meal(String qty) => Meal(
      petId: 1,
      name: 'Dîner',
      time: '19:00',
      food: 'Croquettes',
      quantity: qty,
      calories: 300,
      icon: Icons.restaurant_rounded,
    );

void main() {
  group('parseGrams', () {
    test('reads g and kg, with comma or dot', () {
      expect(parseGrams('100 g'), 100);
      expect(parseGrams('100g'), 100);
      expect(parseGrams('0,5 kg'), 500);
      expect(parseGrams('1.2kg'), 1200);
    });
    test('returns null when no mass is given', () {
      expect(parseGrams('1 boîte'), isNull);
      expect(parseGrams(''), isNull);
    });
  });

  group('FoodStock', () {
    final opened = DateTime(2026, 11, 1);
    final stock = FoodStock(
      petId: 1,
      name: 'Croquettes',
      bagGrams: 3000,
      dailyGrams: 300,
      openedDate: opened,
    );

    test('full on opening day', () {
      expect(stock.remainingGrams(opened), 3000);
      expect(stock.daysLeft(opened), 10);
      expect(stock.remainingRatio(opened), 1);
      expect(stock.isLow(opened), isFalse);
    });

    test('decreases one ration per day', () {
      final day4 = DateTime(2026, 11, 5, 18);
      expect(stock.remainingGrams(day4), 1800);
      expect(stock.daysLeft(day4), 6);
    });

    test('is low within alertDays and never negative', () {
      expect(stock.isLow(DateTime(2026, 11, 8)), isTrue); // 3 days left
      expect(stock.remainingGrams(DateTime(2026, 12, 1)), 0);
      expect(stock.daysLeft(DateTime(2026, 12, 1)), 0);
    });

    test('run-out and alert dates', () {
      expect(stock.runOutDate, DateTime(2026, 11, 11));
      expect(stock.alertDate, DateTime(2026, 11, 8, 9));
    });

    test('round-trips through the database map', () {
      final back = FoodStock.fromMap({...stock.toMap(), 'id': 7});
      expect(back.id, 7);
      expect(back.openedDate, opened);
      expect(back.bagGrams, 3000);
      expect(back.alertDays, 3);
    });
  });

  test('WeightLog round-trips with ISO date', () {
    final log = WeightLog(petId: 2, weight: 12.4, date: DateTime(2026, 3, 9));
    final map = log.toMap();
    expect(map['date'], '2026-03-09');
    final back = WeightLog.fromMap({...map, 'id': 1});
    expect(back.weight, 12.4);
    expect(back.date, DateTime(2026, 3, 9));
  });

  test('suggestedDailyGrams sums meal quantities in grams', () {
    expect(suggestedDailyGrams([_meal('100 g'), _meal('0,2 kg')]), 300);
    expect(suggestedDailyGrams([_meal('1 boîte')]), isNull);
  });

  test('prescription message summarises the diet', () {
    final msg = FoodRepository.prescriptionMessage(
      diet: const Diet(
        petId: 1,
        dietType: 'Hypocalorique',
        goal: 'Perdre 2 kg',
        mealsPerDay: 2,
        notes: '',
      ),
      items: const [
        FoodItem(petId: 1, name: 'Riz', emoji: '🍚', note: '', allowed: true),
        FoodItem(
            petId: 1, name: 'Chocolat', emoji: '🍫', note: '', allowed: false),
      ],
      petName: 'Rex',
      vetName: 'Dr. Martin',
    );
    expect(msg, contains('Dr. Martin'));
    expect(msg, contains('Rex'));
    expect(msg, contains('Hypocalorique'));
    expect(msg, contains('1 autorisé(s), 1 interdit(s)'));
  });
}
