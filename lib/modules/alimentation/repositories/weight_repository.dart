import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

/// Suivi du poids (table `weight_logs`).
///
/// Chaque ajout / modification / suppression recopie la pesée la plus
/// récente dans `pets.weight` pour garder la fiche animal à jour.
class WeightRepository {
  final _db = AppDatabase.instance;

  /// Pesées d'un animal, de la plus ancienne à la plus récente.
  Future<List<WeightLog>> getLogs(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'weight_logs',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(WeightLog.fromMap).toList();
  }

  Future<int> insert(WeightLog log) async {
    final db = await _db.database;
    final id = await db.insert('weight_logs', log.toMap()..remove('id'));
    await _syncPetWeight(log.petId);
    return id;
  }

  Future<void> update(WeightLog log) async {
    if (log.id == null) return;
    final db = await _db.database;
    await db.update(
      'weight_logs',
      log.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [log.id],
    );
    await _syncPetWeight(log.petId);
  }

  Future<void> delete(WeightLog log) async {
    if (log.id == null) return;
    final db = await _db.database;
    await db.delete('weight_logs', where: 'id = ?', whereArgs: [log.id]);
    await _syncPetWeight(log.petId);
  }

  Future<void> _syncPetWeight(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'weight_logs',
      columns: ['weight'],
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return;
    await db.update(
      'pets',
      {'weight': (rows.first['weight'] as num).toDouble()},
      where: 'id = ?',
      whereArgs: [petId],
    );
  }
}
