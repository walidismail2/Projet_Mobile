import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/session.dart';
import '../models/models.dart';

class PetRepository {
  final _db = AppDatabase.instance;
  final FirebaseFirestore _fs;

  PetRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  Future<List<Pet>> getByOwner(String ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'pets',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );
    final pets = rows.map(Pet.fromMap).toList();
    for (final p in pets) {
      await _syncToCloud(p);
    }
    return pets;
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
    final saved = pet.copyWith(id: id);
    await _syncToCloud(saved);
    return saved;
  }

  Future<void> update(Pet pet) async {
    final db = await _db.database;
    await db.update(
      'pets',
      pet.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
    await _syncToCloud(pet);
  }

  Future<void> delete(int id) async {
    final pet = await getById(id);
    final db = await _db.database;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
    if (pet == null) return;
    try {
      await _fs.collection('pets').doc(cloudPetId(pet.ownerId, id)).delete();
      await _fs
          .collection('pet_diets')
          .doc(cloudPetId(pet.ownerId, id))
          .delete();
      final foods = await _fs
          .collection('pet_food_items')
          .where('cloudPetId', isEqualTo: cloudPetId(pet.ownerId, id))
          .get();
      for (final d in foods.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      debugPrint('Cloud delete pet ignored: $e');
    }
  }

  Future<List<Map<String, dynamic>>> findCloudPetsByOwnerEmail(
      String email) async {
    try {
      final snap = await _fs
          .collection('pets')
          .where('ownerEmail', isEqualTo: email.trim().toLowerCase())
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('Cloud search pets failed: $e');
      rethrow;
    }
  }

  Future<void> _syncToCloud(Pet pet) async {
    if (pet.id == null) return;
    try {
      final email =
          (Session.instance.currentUser?.email ?? '').trim().toLowerCase();
      await _fs.collection('pets').doc(cloudPetId(pet.ownerId, pet.id!)).set({
        'ownerId': pet.ownerId,
        'ownerEmail': email,
        'localPetId': pet.id,
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'age': pet.computedAge,
        'weight': pet.weight,
        'sex': pet.sex,
        'emoji': pet.emoji,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ne bloque pas l'app locale si les règles Firestore sont trop strictes.
      debugPrint('Cloud sync pet ignored: $e');
    }
  }
}
