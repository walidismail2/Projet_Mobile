import '../data/app_database.dart';
import '../data/session.dart';
import '../models/models.dart';
import 'pet_repository.dart';
import 'vet_repository.dart';

class AppointmentRepository {
  final _db = AppDatabase.instance;
  final _pets = PetRepository();
  final _vets = VetRepository();

  Future<List<Appointment>> getAll({AppointmentStatus? status}) async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return [];

    final pets = await _pets.getByOwner(ownerId);
    final petIds = pets.map((p) => p.id).whereType<int>().toList();
    if (petIds.isEmpty) return [];

    final db = await _db.database;
    final placeholders = List.filled(petIds.length, '?').join(',');
    final where = status == null
        ? 'pet_id IN ($placeholders)'
        : 'pet_id IN ($placeholders) AND status = ?';
    final args = status == null
        ? <Object>[...petIds]
        : <Object>[...petIds, status.name];

    final rows = await db.query(
      'appointments',
      where: where,
      whereArgs: args,
      orderBy: 'id DESC',
    );

    final result = <Appointment>[];
    for (final row in rows) {
      var a = Appointment.fromMap(row);
      Vet? vet;
      if (a.vetId.isNotEmpty) {
        vet = await _vets.getById(a.vetId);
      } else {
        final cached = await _vets.getVets();
        vet = cached.isEmpty ? null : cached.first;
      }
      final pet = await _pets.getById(a.petId);
      result.add(a.copyWith(vet: vet, pet: pet));
    }
    return result;
  }

  Future<int> insert(Appointment a) async {
    final db = await _db.database;
    return db.insert('appointments', a.toMap()..remove('id'));
  }

  Future<void> updateStatus(int id, AppointmentStatus status) async {
    final db = await _db.database;
    await db.update(
      'appointments',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
