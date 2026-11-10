import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/user_repository.dart';
import 'package:flutter_example/core/data/auth_prefs.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  final AuthPrefs prefs = AuthPrefs();
  final UserRepository _users = UserRepository();
  AppUser? currentUser;

  String? get userId => currentUser?.id;

  Future<bool> restore() async {
    if (!await prefs.hasSession()) return false;
    currentUser = await prefs.getUser();
    if (currentUser != null) {
      final fromDb = await _users.getById(currentUser!.id);
      if (fromDb != null) {
        currentUser = fromDb;
        await prefs.updateUser(fromDb);
      } else {
        await _users.upsert(currentUser!);
      }
    }
    return currentUser != null;
  }

  Future<void> signIn(AppUser user, {required bool remember}) async {
    currentUser = user;
    await prefs.setSession(user, remember: remember);
    await _users.upsert(user);
  }

  Future<void> signOut() async {
    currentUser = null;
    await prefs.clearSession();
  }

  Future<void> updateLocalProfile(AppUser user) async {
    currentUser = user;
    await prefs.updateUser(user);
    await _users.upsert(user);
  }
}
