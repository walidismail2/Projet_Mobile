import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

class FoodRepository {
  final _db = AppDatabase.instance;

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

  Future<void> setMealDone(int id, bool done) async {
    final db = await _db.database;
    await db.update(
      'meals',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  Future<void> deleteMeal(int id) async {
    final db = await _db.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  // ——— Régime / aliments ———

  Future<Diet?> getDiet({
    required String ownerId,
    required int petId,
  }) async {
    return _getDietLocal(petId);
  }

  Future<Diet?> getDietForCurrentOwner(int petId) async {
    return _getDietLocal(petId);
  }

  Future<Diet?> _getDietLocal(int petId) async {
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

  Future<void> upsertDiet({
    required String ownerId,
    required Diet diet,
    String? prescribedBy,
  }) async {
    final db = await _db.database;
    await db.delete('diets', where: 'pet_id = ?', whereArgs: [diet.petId]);
    await db.insert('diets', diet.toMap()..remove('id'));
  }

  Future<List<FoodItem>> getFoodItems({
    required String ownerId,
    required int petId,
    required bool allowed,
  }) async {
    return _getFoodItemsLocal(petId, allowed: allowed);
  }

  Future<List<FoodItem>> getFoodItemsForCurrentOwner(
    int petId, {
    required bool allowed,
  }) async {
    return _getFoodItemsLocal(petId, allowed: allowed);
  }

  Future<List<FoodItem>> _getFoodItemsLocal(int petId,
      {required bool allowed}) async {
    final db = await _db.database;
    final rows = await db.query(
      'food_items',
      where: 'pet_id = ? AND allowed = ?',
      whereArgs: [petId, allowed ? 1 : 0],
      orderBy: 'id ASC',
    );
    return rows.map(FoodItem.fromMap).toList();
  }

  Future<void> replaceFoodItems({
    required String ownerId,
    required int petId,
    required List<FoodItem> items,
  }) async {
    final db = await _db.database;
    await db.delete('food_items', where: 'pet_id = ?', whereArgs: [petId]);
    for (final item in items) {
      await db.insert('food_items', item.toMap()..remove('id'));
    }
  }
}
