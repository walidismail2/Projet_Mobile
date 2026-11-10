import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';

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
        .where((n) => n.petId == null || petIds.contains(n.petId))
        .toList();
  }

  Future<int> unreadCount() async {
    final items = await getNotifications();
    return items.where((n) => n.unread).length;
  }

  Future<void> markAllRead() async {
    final petIds = await _ownerPetIds();
    final db = await _db.database;
    if (petIds.isEmpty) {
      await db.update(
        'notifications',
        {'unread': 0},
        where: 'pet_id IS NULL',
      );
      return;
    }
    final placeholders = List.filled(petIds.length, '?').join(',');
    await db.update(
      'notifications',
      {'unread': 0},
      where: 'pet_id IS NULL OR pet_id IN ($placeholders)',
      whereArgs: petIds.toList(),
    );
  }

  Future<List<CustomReminder>> getCustomReminders() async {
    final db = await _db.database;
    final rows = await db.query('custom_reminders', orderBy: 'id DESC');
    return rows.map(CustomReminder.fromMap).toList();
  }

  Future<void> insertNotification(AppNotification notification) async {
    final db = await _db.database;
    await db.insert('notifications', notification.toMap()..remove('id'));
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

  Future<void> updateCustomReminder(CustomReminder r) async {
    if (r.id == null) return;
    final db = await _db.database;
    await db.update(
      'custom_reminders',
      r.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<void> deleteCustomReminder(int id) async {
    final db = await _db.database;
    await db.delete('custom_reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNotification(int id) async {
    final db = await _db.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }
}
