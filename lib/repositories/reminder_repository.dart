import '../data/app_database.dart';
import '../data/session.dart';
import '../models/models.dart';
import 'pet_repository.dart';

class ReminderRepository {
  final _db = AppDatabase.instance;
  final _pets = PetRepository();

  Future<Set<int>> _ownerPetIds() async {
    final ownerId = Session.instance.userId;
    if (ownerId == null) return {};
    final pets = await _pets.getByOwner(ownerId);
    return pets.map((p) => p.id).whereType<int>().toSet();
  }

  Future<List<AppNotification>> getNotifications({NotificationType? type}) async {
    final petIds = await _ownerPetIds();
    final db = await _db.database;
    final rows = type == null
        ? await db.query('notifications', orderBy: 'id DESC')
        : await db.query(
            'notifications',
            where: 'type = ?',
            whereArgs: [type.name],
            orderBy: 'id DESC',
          );
    return rows
        .map(AppNotification.fromMap)
        .where((n) => n.petId != null && petIds.contains(n.petId))
        .toList();
  }

  Future<void> markAllRead() async {
    final petIds = await _ownerPetIds();
    if (petIds.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(petIds.length, '?').join(',');
    await db.update(
      'notifications',
      {'unread': 0},
      where: 'pet_id IN ($placeholders)',
      whereArgs: petIds.toList(),
    );
  }

  Future<int> insertCustomReminder(CustomReminder r) async {
    final db = await _db.database;
    final id = await db.insert('custom_reminders', r.toMap()..remove('id'));
    await db.insert(
      'notifications',
      AppNotification(
        petId: r.petId,
        title: r.title,
        message: 'Rappel ${r.category} · ${r.date} à ${r.time}',
        time: "À l'instant",
        type: NotificationType.custom,
        unread: true,
      ).toMap()
        ..remove('id'),
    );
    return id;
  }
}
