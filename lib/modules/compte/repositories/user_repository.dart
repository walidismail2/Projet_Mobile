import 'package:sqflite/sqflite.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

class UserAuthRow {
  final AppUser user;
  final String passwordHash;
  final String salt;

  const UserAuthRow({
    required this.user,
    required this.passwordHash,
    required this.salt,
  });
}

/// Module Compte — profil utilisateur en SQLite.
class UserRepository {
  final _db = AppDatabase.instance;

  Future<AppUser?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getByEmail(String email) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<UserAuthRow?> getAuthRowByEmail(String email) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final m = rows.first;
    return UserAuthRow(
      user: AppUser.fromMap(m),
      passwordHash: (m['password_hash'] as String?) ?? '',
      salt: (m['password_salt'] as String?) ?? '',
    );
  }

  Future<bool> emailExists(String email) async {
    return (await getByEmail(email)) != null;
  }

  Future<void> insertWithPassword({
    required AppUser user,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await _db.database;
    await db.insert('users', {
      ...user.toMap(),
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
    });
  }

  Future<void> upsert(AppUser user) async {
    final db = await _db.database;
    final existing = await getById(user.id);
    if (existing == null) {
      await db.insert(
        'users',
        {
          ...user.toMap(),
          'password_hash': '',
          'password_salt': '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    await db.update(
      'users',
      {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.name,
        'address': user.address,
        'latitude': user.latitude,
        'longitude': user.longitude,
        'photo_path': user.photoPath,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> update(AppUser user) async {
    await upsert(user);
  }

  Future<UserAuthRow?> getAuthRowById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return UserAuthRow(
      user: AppUser.fromMap(m),
      passwordHash: (m['password_hash'] as String?) ?? '',
      salt: (m['password_salt'] as String?) ?? '',
    );
  }

  Future<void> updatePassword({
    required String userId,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
