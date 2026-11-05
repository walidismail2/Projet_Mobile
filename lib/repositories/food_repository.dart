import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_database.dart';
import '../data/session.dart';
import '../models/models.dart';

class FoodRepository {
  final _db = AppDatabase.instance;
  final FirebaseFirestore _fs;

  FoodRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  // ——— Repas : locaux (propriétaire) ———

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

  // ——— Régime / aliments : Firestore (prescrit par le véto) ———

  String _dietDoc(String ownerId, int petId) => cloudPetId(ownerId, petId);

  Future<Diet?> getDiet({
    required String ownerId,
    required int petId,
  }) async {
    final doc =
        await _fs.collection('pet_diets').doc(_dietDoc(ownerId, petId)).get();
    if (!doc.exists || doc.data() == null) return null;
    final d = doc.data()!;
    return Diet(
      petId: petId,
      dietType: d['dietType']?.toString() ?? '',
      goal: d['goal']?.toString() ?? '',
      mealsPerDay: (d['mealsPerDay'] as num?)?.toInt() ?? 3,
      notes: d['notes']?.toString() ?? '',
    );
  }

  /// Compat écrans qui passent seulement le petId local (owner = session).
  Future<Diet?> getDietForCurrentOwner(int petId) async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return null;
    return getDiet(ownerId: ownerId, petId: petId);
  }

  Future<void> upsertDiet({
    required String ownerId,
    required Diet diet,
    String? prescribedBy,
  }) async {
    await _fs.collection('pet_diets').doc(_dietDoc(ownerId, diet.petId)).set({
      'ownerId': ownerId,
      'localPetId': diet.petId,
      'dietType': diet.dietType,
      'goal': diet.goal,
      'mealsPerDay': diet.mealsPerDay,
      'notes': diet.notes,
      'prescribedBy': prescribedBy ?? Session.instance.userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<FoodItem>> getFoodItems({
    required String ownerId,
    required int petId,
    required bool allowed,
  }) async {
    final snap = await _fs
        .collection('pet_food_items')
        .where('cloudPetId', isEqualTo: cloudPetId(ownerId, petId))
        .where('allowed', isEqualTo: allowed)
        .get();
    return snap.docs.map((d) {
      final m = d.data();
      return FoodItem(
        petId: petId,
        name: m['name']?.toString() ?? '',
        emoji: m['emoji']?.toString() ?? '🍽️',
        note: m['note']?.toString() ?? '',
        allowed: m['allowed'] == true,
      );
    }).toList();
  }

  Future<List<FoodItem>> getFoodItemsForCurrentOwner(
    int petId, {
    required bool allowed,
  }) async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return [];
    return getFoodItems(ownerId: ownerId, petId: petId, allowed: allowed);
  }

  Future<void> replaceFoodItems({
    required String ownerId,
    required int petId,
    required List<FoodItem> items,
  }) async {
    final cloudId = cloudPetId(ownerId, petId);
    final existing = await _fs
        .collection('pet_food_items')
        .where('cloudPetId', isEqualTo: cloudId)
        .get();
    for (final d in existing.docs) {
      await d.reference.delete();
    }
    for (final item in items) {
      await _fs.collection('pet_food_items').add({
        'cloudPetId': cloudId,
        'ownerId': ownerId,
        'localPetId': petId,
        'name': item.name,
        'emoji': item.emoji,
        'note': item.note,
        'allowed': item.allowed,
      });
    }
  }
}
