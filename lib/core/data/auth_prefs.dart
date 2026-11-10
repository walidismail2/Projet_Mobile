import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_example/core/models/models.dart';

class AuthPrefs {
  static const _rememberKey = 'remember_me';
  static const _idKey = 'user_id';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _phoneKey = 'user_phone';
  static const _roleKey = 'user_role';
  static const _addressKey = 'user_address';
  static const _latKey = 'user_lat';
  static const _lonKey = 'user_lon';
  static const _seededKey = 'seeded_owner_';
  static const _reminderPrefix = 'reminder_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> hasSession() async {
    final p = await _prefs;
    return (p.getBool(_rememberKey) ?? false) &&
        (p.getString(_idKey)?.isNotEmpty ?? false);
  }

  Future<AppUser?> getUser() async {
    final p = await _prefs;
    final id = p.getString(_idKey);
    if (id == null || id.isEmpty) return null;
    return AppUser(
      id: id,
      name: p.getString(_nameKey) ?? '',
      email: p.getString(_emailKey) ?? '',
      phone: p.getString(_phoneKey) ?? '',
      role: userRoleFromString(p.getString(_roleKey)),
      address: p.getString(_addressKey) ?? '',
      latitude: p.getDouble(_latKey),
      longitude: p.getDouble(_lonKey),
    );
  }

  Future<void> setSession(AppUser user, {required bool remember}) async {
    final p = await _prefs;
    await p.setBool(_rememberKey, remember);
    await p.setString(_idKey, user.id);
    await p.setString(_nameKey, user.name);
    await p.setString(_emailKey, user.email);
    await p.setString(_phoneKey, user.phone);
    await p.setString(_roleKey, user.role.name);
    await p.setString(_addressKey, user.address);
    if (user.latitude != null) {
      await p.setDouble(_latKey, user.latitude!);
    } else {
      await p.remove(_latKey);
    }
    if (user.longitude != null) {
      await p.setDouble(_lonKey, user.longitude!);
    } else {
      await p.remove(_lonKey);
    }
  }

  Future<void> updateUser(AppUser user) async {
    final p = await _prefs;
    await p.setString(_nameKey, user.name);
    await p.setString(_emailKey, user.email);
    await p.setString(_phoneKey, user.phone);
    await p.setString(_roleKey, user.role.name);
    await p.setString(_addressKey, user.address);
    if (user.latitude != null) {
      await p.setDouble(_latKey, user.latitude!);
    } else {
      await p.remove(_latKey);
    }
    if (user.longitude != null) {
      await p.setDouble(_lonKey, user.longitude!);
    } else {
      await p.remove(_lonKey);
    }
  }

  Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_rememberKey);
    await p.remove(_idKey);
    await p.remove(_nameKey);
    await p.remove(_emailKey);
    await p.remove(_phoneKey);
    await p.remove(_roleKey);
    await p.remove(_addressKey);
    await p.remove(_latKey);
    await p.remove(_lonKey);
  }

  Future<bool> isOwnerSeeded(String ownerId) async {
    final p = await _prefs;
    return p.getBool('$_seededKey$ownerId') ?? false;
  }

  Future<void> markOwnerSeeded(String ownerId) async {
    final p = await _prefs;
    await p.setBool('$_seededKey$ownerId', true);
  }

  Future<bool> getReminderEnabled(String type, {bool defaultValue = true}) async {
    final p = await _prefs;
    return p.getBool('$_reminderPrefix$type') ?? defaultValue;
  }

  Future<void> setReminderEnabled(String type, bool value) async {
    final p = await _prefs;
    await p.setBool('$_reminderPrefix$type', value);
  }

  Future<bool> getMasterNotifications({bool defaultValue = true}) async {
    final p = await _prefs;
    return p.getBool('${_reminderPrefix}master') ?? defaultValue;
  }

  Future<void> setMasterNotifications(bool value) async {
    final p = await _prefs;
    await p.setBool('${_reminderPrefix}master', value);
  }

  Future<bool> getBool(String key, {bool defaultValue = true}) async {
    final p = await _prefs;
    return p.getBool('$_reminderPrefix$key') ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool('$_reminderPrefix$key', value);
  }
}
