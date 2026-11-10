import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/data/document_storage.dart';
import 'package:flutter_example/core/models/models.dart';

class HealthRepository {
  final _db = AppDatabase.instance;

  Future<List<Vaccine>> getVaccines(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'vaccines',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'id DESC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<int> insertVaccine(Vaccine v) async {
    final db = await _db.database;
    final id = await db.insert(
      'vaccines',
      v.withComputedStatus().toMap()..remove('id'),
    );
    AppRefresh.instance.healthChanged();
    return id;
  }

  Future<void> updateVaccine(Vaccine v) async {
    if (v.id == null) return;
    final db = await _db.database;
    await db.update(
      'vaccines',
      v.withComputedStatus().toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [v.id],
    );
    AppRefresh.instance.healthChanged();
  }

  Future<void> deleteVaccine(int id) async {
    final db = await _db.database;
    await db.delete('vaccines', where: 'id = ?', whereArgs: [id]);
    AppRefresh.instance.healthChanged();
  }

  Future<List<Treatment>> getTreatments(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'treatments',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'id DESC',
    );
    return rows.map(Treatment.fromMap).toList();
  }

  Future<int> insertTreatment(Treatment t) async {
    final db = await _db.database;
    final id = await db.insert('treatments', t.toMap()..remove('id'));
    AppRefresh.instance.healthChanged();
    return id;
  }

  Future<void> updateTreatment(Treatment t) async {
    if (t.id == null) return;
    final db = await _db.database;
    await db.update(
      'treatments',
      t.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [t.id],
    );
    AppRefresh.instance.healthChanged();
  }

  Future<void> advanceTreatmentDay(Treatment t) async {
    if (t.id == null || t.isCompleted) return;
    final db = await _db.database;
    final next = (t.currentDay + 1).clamp(0, t.totalDays);
    await db.update(
      'treatments',
      {'current_day': next},
      where: 'id = ?',
      whereArgs: [t.id],
    );
    AppRefresh.instance.healthChanged();
  }

  Future<void> deleteTreatment(int id) async {
    final db = await _db.database;
    await db.delete('treatments', where: 'id = ?', whereArgs: [id]);
    AppRefresh.instance.healthChanged();
  }

  Future<List<MedicalDocument>> getDocuments(int petId) async {
    final db = await _db.database;
    final rows = await db.query(
      'medical_documents',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'id DESC',
    );
    return rows.map(MedicalDocument.fromMap).toList();
  }

  Future<int> insertDocument(MedicalDocument d) async {
    final db = await _db.database;
    final id = await db.insert('medical_documents', d.toMap()..remove('id'));
    AppRefresh.instance.healthChanged();
    return id;
  }

  Future<void> deleteDocument(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'medical_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await DocumentStorage.deleteIfExists(rows.first['file_path'] as String?);
    }
    await db.delete('medical_documents', where: 'id = ?', whereArgs: [id]);
    AppRefresh.instance.healthChanged();
  }

  /// Résumé santé pour un animal (écran + home).
  Future<({int vaccinesOk, int vaccinesLate, int treatmentsActive})>
      summaryForPet(int petId) async {
    final vaccines = await getVaccines(petId);
    final treatments = await getTreatments(petId);
    return (
      vaccinesOk:
          vaccines.where((v) => v.status == HealthStatus.upToDate).length,
      vaccinesLate: vaccines
          .where((v) =>
              v.status == HealthStatus.late || v.status == HealthStatus.soon)
          .length,
      treatmentsActive: treatments.where((t) => !t.isCompleted).length,
    );
  }
}
