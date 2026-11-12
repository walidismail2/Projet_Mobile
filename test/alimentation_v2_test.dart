import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/services/food_safety_service.dart';
import 'package:flutter_example/modules/alimentation/services/pet_food_api_service.dart';

Meal _meal({DateTime? date, DateTime? createdOn}) => Meal(
  id: 1,
  petId: 1,
  name: 'Dîner',
  time: '19:00',
  food: 'Croquettes',
  quantity: '100 g',
  calories: 350,
  icon: Icons.restaurant_rounded,
  date: date,
  createdOn: createdOn,
);

void main() {
  group('Meal dates', () {
    test('daily meal applies from its creation day onwards', () {
      final m = _meal(createdOn: DateTime(2026, 11, 10, 15));
      expect(m.isDaily, isTrue);
      expect(m.appliesOn(DateTime(2026, 11, 9)), isFalse);
      expect(m.appliesOn(DateTime(2026, 11, 10, 7)), isTrue);
      expect(m.appliesOn(DateTime(2027, 1, 1)), isTrue);
    });

    test('one-off meal applies only on its date', () {
      final m = _meal(date: DateTime(2026, 11, 12, 20));
      expect(m.appliesOn(DateTime(2026, 11, 12)), isTrue);
      expect(m.appliesOn(DateTime(2026, 11, 13)), isFalse);
    });

    test('round-trips through the database map', () {
      final m = _meal(
        date: DateTime(2026, 11, 12),
        createdOn: DateTime(2026, 11, 1),
      );
      final back = Meal.fromMap(m.toMap());
      expect(back.date, DateTime(2026, 11, 12));
      expect(back.createdOn, DateTime(2026, 11, 1));
      expect(m.toMap()['done'], 0);
    });

    test('rows migrated without created_on still load', () {
      final map = _meal().toMap()
        ..remove('created_on')
        ..remove('date');
      expect(Meal.fromMap(map).isDaily, isTrue);
    });

    test('a log keeps a snapshot of the meal for that day', () {
      final log = MealLog.fromMeal(_meal(), DateTime(2026, 11, 12, 21));
      expect(log.date, DateTime(2026, 11, 12));
      expect(log.calories, 350);
      final entry = MealEntry(meal: _meal(), log: log);
      expect(entry.done, isTrue);
      expect(MealEntry(meal: _meal()).done, isFalse);
    });
  });

  test('normalizeText removes accents, ligatures and extra spaces', () {
    expect(normalizeText('  Œuf   Crû  '), 'oeuf cru');
    expect(normalizeText('Échalote'), 'echalote');
  });

  group('FoodSafetyService.lookup', () {
    test('chocolate is toxic for a dog', () {
      final r = FoodSafetyService.lookup('chocolat', species: 'Chien');
      expect(r.first.level, SafetyLevel.toxic);
    });

    test('prefix typing and accents work', () {
      expect(
        FoodSafetyService.lookup('écha', species: 'Chat').first.title,
        contains('Oignon'),
      );
    });

    test('xylitol is toxic for dogs but caution for cats', () {
      expect(
        FoodSafetyService.lookup('xylitol', species: 'Chien').first.level,
        SafetyLevel.toxic,
      );
      expect(
        FoodSafetyService.lookup('xylitol', species: 'Chat').first.level,
        SafetyLevel.caution,
      );
    });

    test('lilies are toxic for cats only', () {
      expect(
        FoodSafetyService.lookup('lys', species: 'Chat').first.level,
        SafetyLevel.toxic,
      );
      expect(
        FoodSafetyService.lookup('lys', species: 'Chien').first.level,
        SafetyLevel.caution,
      );
    });

    test('vet lists are included and sorted by severity', () {
      final r = FoodSafetyService.lookup(
        'carotte',
        species: 'Chien',
        vetItems: const [
          FoodItem(
            petId: 1,
            name: 'Carottes',
            emoji: '🥕',
            note: 'Trop sucré pour le régime',
            allowed: false,
          ),
        ],
      );
      expect(r.first.level, SafetyLevel.vetForbidden);
      expect(r.last.level, SafetyLevel.safe);
    });

    test('a full word inside a longer query matches', () {
      final r = FoodSafetyService.lookup('fromage blanc', species: 'Chien');
      expect(r.single.title, contains('fromage'));
    });

    test('unknown or too short queries give nothing', () {
      expect(FoodSafetyService.lookup('zzz', species: 'Chien'), isEmpty);
      expect(FoodSafetyService.lookup('c', species: 'Chien'), isEmpty);
    });
  });

  group('FoodSafetyService.checkText', () {
    test('finds toxic ingredients as whole words only', () {
      final r = FoodSafetyService.checkText(
        'Poulet, riz, poudre d\'oignons, détail du produit',
        species: 'Chien',
        includeCaution: false,
      );
      expect(r.map((e) => e.title), [contains('Oignon')]);
    });

    test('ingredient mode ignores caution items like salt and milk', () {
      expect(
        FoodSafetyService.checkText(
          'sel, lait en poudre',
          species: 'Chat',
          includeCaution: false,
        ),
        isEmpty,
      );
      expect(FoodSafetyService.checkText('sel', species: 'Chat'), isNotEmpty);
    });

    test('flags foods the vet forbade', () {
      final r = FoodSafetyService.checkText(
        'Pâtée au boeuf',
        species: 'Chien',
        vetItems: const [
          FoodItem(
            petId: 1,
            name: 'Boeuf',
            emoji: '🥩',
            note: '',
            allowed: false,
          ),
        ],
      );
      expect(r.single.level, SafetyLevel.vetForbidden);
    });
  });

  group('Open Pet Food Facts parsing', () {
    // Extraits réels de world.openpetfoodfacts.org (nov. 2026).
    final kitten = <String, dynamic>{
      'code': '3182550702423',
      'product_name': 'kitten 12mois',
      'brands': 'Royal canin',
      'quantity': '2kg',
      'categories_tags': [
        'en:dog-and-cat-food',
        'en:cat-food',
        'en:dry-cat-food',
      ],
      'nutriments': {
        'crude-ash_100g': 7.8,
        'crude-fat_100g': 18,
        'crude-fibre_100g': 2.3,
        'crude-protein_100g': 36,
        'energy-kcal_100g': 0,
        'energy-kj_100g': 0,
        'moisture_100g': 5.5,
      },
      'ingredients_text_fr': 'protéines de volaille déshydratées, maïs',
    };

    test('estimates kcal from the guaranteed analysis', () {
      final p = PetFoodApiService.productFromJson(kitten)!;
      // 3,5×36 + 8,5×18 + 3,5×(100−36−18−2,3−7,8−5,5) = 385,4
      expect(p.kcalPer100g, closeTo(385.4, 0.1));
      expect(p.kcalEstimated, isTrue);
      expect(p.species, 'cat');
      expect(p.displayName, 'Royal canin · kitten 12mois');
    });

    test('ignores implausible declared energy', () {
      final k = PetFoodApiService.estimateKcalPer100g(
        {
          'energy-kj_100g': 107.3,
          'crude-protein_100g': 37,
          'crude-fat_100g': 12,
        },
        ['en:dry-cat-food'],
      )!;
      expect(k.$2, isTrue); // 25 kcal déclarés → rejeté, estimé à la place
      expect(k.$1, greaterThan(250));
    });

    test('uses plausible declared kcal as is', () {
      expect(
        PetFoodApiService.estimateKcalPer100g({'energy-kcal_100g': 92}, []),
        (92.0, false),
      );
    });

    test('no nutrition data gives no kcal; no name gives no product', () {
      expect(PetFoodApiService.estimateKcalPer100g({}, []), isNull);
      expect(
        PetFoodApiService.productFromJson({'code': '1', 'brands': 'X'}),
        isNull,
      );
    });

    test('rejects impossible analyses instead of showing a wrong kcal', () {
      // « adult mini 8+ » (2 kg) : protéines 2,7 % / MG 1,6 % saisies au
      // lieu de 27 % / 16 %, kJ déclarés = 25 kcal.
      final miniAdult = PetFoodApiService.productFromJson({
        'code': '3182550831383',
        'product_name': 'adult mini 8+',
        'brands': 'royal canin',
        'quantity': '2kg',
        'categories_tags': ['en:dog-food'],
        'nutriments': {
          'energy-kcal_100g': 0.4,
          'energy-kj_100g': 106.8,
          'fat_100g': 1.6,
          'proteins_100g': 2.7,
        },
      })!;
      expect(miniAdult.kcalPer100g, isNull);
      // Pâtée 85 g avec 0,92 % de protéines : aussi rejetée.
      expect(
        PetFoodApiService.estimateKcalPer100g(
          {'fat_100g': 2.5, 'proteins_100g': 0.92},
          ['en:cat-food'],
          packGrams: 85,
        ),
        isNull,
      );
    });

    test('a big bag is treated as dry food', () {
      final k = PetFoodApiService.estimateKcalPer100g(
        {'crude-protein_100g': 26, 'crude-fat_100g': 16},
        ['en:dog-food'],
        packGrams: 3000,
      )!;
      // 3,5×26 + 8,5×16 + 3,5×(100−26−16−3−7−10) = 360
      expect(k.$1, closeTo(360, 0.1));
    });

    test('maps pet species to API tags', () {
      expect(PetFoodApiService.speciesTag('Chien'), 'dog');
      expect(PetFoodApiService.speciesTag('Chat'), 'cat');
      expect(PetFoodApiService.speciesTag('Lapin'), isNull);
    });
  });
}
