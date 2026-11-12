import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

/// Stock de nourriture (table `food_stock`).
class FoodStockRepository {
  final _db = AppDatabase.instance;

  Future<List<FoodStock>> getStocks(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'food_stock',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'id ASC',
    );
    return rows.map(FoodStock.fromMap).toList();
  }

  Future<int> insert(FoodStock stock) async {
    final db = await _db.database;
    return db.insert('food_stock', stock.toMap()..remove('id'));
  }

  Future<void> update(FoodStock stock) async {
    if (stock.id == null) return;
    final db = await _db.database;
    await db.update(
      'food_stock',
      stock.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('food_stock', where: 'id = ?', whereArgs: [id]);
  }
}
