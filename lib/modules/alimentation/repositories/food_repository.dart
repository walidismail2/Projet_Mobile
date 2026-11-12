import 'package:sqflite/sqflite.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

class FoodRepository {
  final _db = AppDatabase.instance;

  /// Tables du module Alimentation liées à un animal (`pet_id`).
  static const petTables = [
    'meals',
    'meal_logs',
    'diets',
    'food_items',
    'weight_logs',
    'food_stock',
  ];

  /// Supprime toutes les données Alimentation d'un animal.
  /// Appelé dans la même transaction que la suppression de l'animal.
  static Future<void> deleteAllForPet(DatabaseExecutor db, int petId) async {
    for (final table in petTables) {
      await db.delete(table, where: 'pet_id = ?', whereArgs: [petId]);
    }
  }

  // ——— Repas ———

  Future<List<Meal>> getMeals(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'meals',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'time ASC',
    );
    return rows.map(Meal.fromMap).toList();
  }

  Future<int> insertMeal(Meal meal) async {
    final db = await _db.database;
    return db.insert('meals', meal.toMap()..remove('id'));
  }

  /// Repas d'un jour : repas prévus ce jour-là (+ « fait » si loggé) et
  /// logs dont le repas a été supprimé / modifié depuis. Triés par heure.
  Future<List<MealEntry>> getDay(int petId, DateTime day) async {
    final db = await _db.database;
    final meals = (await getMeals(petId)).where((m) => m.appliesOn(day));
    final logRows = await db.query(
      'meal_logs',
      where: 'pet_id = ? AND date = ?',
      whereArgs: [petId, isoDate(day)],
    );
    final logs = logRows.map(MealLog.fromMap).toList();
    final byMeal = {for (final l in logs) l.mealId: l};
    final entries = [
      for (final m in meals) MealEntry(meal: m, log: byMeal.remove(m.id)),
      for (final l in byMeal.values) MealEntry(log: l),
    ];
    entries.sort((a, b) => a.time.compareTo(b.time));
    return entries;
  }

  /// Coche / décoche un repas pour un jour donné.
  Future<void> setDone(Meal meal, DateTime day, bool done) async {
    final db = await _db.database;
    if (done) {
      await db.insert(
        'meal_logs',
        MealLog.fromMeal(meal, day).toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'meal_logs',
        where: 'meal_id = ? AND date = ?',
        whereArgs: [meal.id, isoDate(day)],
      );
    }
  }

  /// Historique des repas « faits » (`meal_logs`) d'un animal, du plus
  /// récent au plus ancien. Période et type filtrés en SQL ; le texte est
  /// filtré ensuite (`filterLogsByText`, insensible aux accents).
  Future<List<MealLog>> getLogs(
    int petId, {
    DateTime? from,
    DateTime? to,
    String? mealName,
  }) async {
    final db = await _db.database;
    final where = [
      'pet_id = ?',
      if (from != null) 'date >= ?',
      if (to != null) 'date <= ?',
      if (mealName != null) 'meal_name = ?',
    ].join(' AND ');
    final rows = await db.query(
      'meal_logs',
      where: where,
      whereArgs: [
        petId,
        if (from != null) isoDate(from),
        if (to != null) isoDate(to),
        ?mealName,
      ],
      orderBy: 'date DESC, time DESC',
    );
    return rows.map(MealLog.fromMap).toList();
  }

  Future<void> deleteLog(int logId) async {
    final db = await _db.database;
    await db.delete('meal_logs', where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> updateMeal(Meal meal) async {
    if (meal.id == null) return;
    final db = await _db.database;
    await db.update(
      'meals',
      meal.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  /// Supprime le repas planifié ; ses logs restent dans l'historique.
  Future<void> deleteMeal(int id) async {
    final db = await _db.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  // ——— Régime / aliments (prescrits par le véto) ———

  Future<Diet?> getDiet(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'diets',
      where: 'pet_id = ?',
      whereArgs: [petId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Diet.fromMap(rows.first);
  }

  Future<List<FoodItem>> getFoodItems(
    int petId, {
    required bool allowed,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'food_items',
      where: 'pet_id = ? AND allowed = ?',
      whereArgs: [petId, allowed ? 1 : 0],
      orderBy: 'id ASC',
    );
    return rows.map(FoodItem.fromMap).toList();
  }

  /// Enregistre la prescription du véto (régime + aliments) en une
  /// transaction et dépose une notification dans la boîte du propriétaire.
  ///
  /// La notification porte `pet_id` : elle n'est visible que pour le
  /// propriétaire de l'animal (voir `ReminderRepository.getNotifications`).
  Future<void> savePrescription({
    required Diet diet,
    required List<FoodItem> items,
    required String petName,
    String? vetName,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('diets', where: 'pet_id = ?', whereArgs: [diet.petId]);
      await txn.insert('diets', diet.toMap()..remove('id'));

      await txn.delete(
        'food_items',
        where: 'pet_id = ?',
        whereArgs: [diet.petId],
      );
      for (final item in items) {
        await txn.insert('food_items', item.toMap()..remove('id'));
      }

      await txn.insert(
        'notifications',
        AppNotification(
          petId: diet.petId,
          title: 'Nouvelle prescription 🩺',
          message: prescriptionMessage(
            diet: diet,
            items: items,
            petName: petName,
            vetName: vetName,
          ),
          time: "À l'instant",
          type: NotificationType.meal,
          unread: true,
        ).toMap()..remove('id'),
      );
    });
  }

  static String prescriptionMessage({
    required Diet diet,
    required List<FoodItem> items,
    required String petName,
    String? vetName,
  }) {
    final who = (vetName == null || vetName.trim().isEmpty)
        ? 'Votre vétérinaire'
        : vetName.trim();
    final allowed = items.where((i) => i.allowed).length;
    final forbidden = items.length - allowed;
    final type = diet.dietType.isEmpty ? 'Régime' : diet.dietType;
    return '$who a mis à jour le régime de $petName : $type · '
        '${diet.mealsPerDay} repas/j · $allowed autorisé(s), '
        '$forbidden interdit(s).';
  }
}
