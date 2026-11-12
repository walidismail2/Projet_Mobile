import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';

class PetRepository {
  final _db = AppDatabase.instance;

  Future<List<Pet>> getByOwner(String ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'pets',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );
    return rows.map(Pet.fromMap).toList();
  }

  Future<Pet?> getById(int id) async {
    final db = await _db.database;
    final rows =
        await db.query('pets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Pet.fromMap(rows.first);
  }

  Future<Pet> insert(Pet pet) async {
    final db = await _db.database;
    final id = await db.insert('pets', pet.toMap()..remove('id'));
    return pet.copyWith(id: id);
  }

  Future<void> update(Pet pet) async {
    final db = await _db.database;
    await db.update(
      'pets',
      pet.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  /// Supprime l'animal et ses données Alimentation (repas, régime,
  /// aliments, pesées, stock) dans une seule transaction.
  /// Annuler les notifications avant : `LocalNotifications.cancelForPet`.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await FoodRepository.deleteAllForPet(txn, id);
      await txn.delete('pets', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Recherche locale des animaux d’un propriétaire par e-mail (module véto).
  Future<List<Map<String, dynamic>>> findPetsByOwnerEmail(String email) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, u.id AS owner_uid
      FROM pets p
      INNER JOIN users u ON u.id = p.owner_id
      WHERE LOWER(u.email) = ?
      ORDER BY p.name ASC
      ''',
      [email.trim().toLowerCase()],
    );
    return rows.map((m) {
      final pet = Pet.fromMap(m);
      return <String, dynamic>{
        'ownerId': pet.ownerId,
        'localPetId': pet.id,
        'name': pet.name,
        'emoji': pet.emoji,
        'species': pet.species,
        'breed': pet.breed,
      };
    }).toList();
  }
}
