import '../models/models.dart';
import 'auth_prefs.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  final AuthPrefs prefs = AuthPrefs();
  AppUser? currentUser;

  String? get userId => currentUser?.id;

  Future<bool> restore() async {
    if (!await prefs.hasSession()) return false;
    currentUser = await prefs.getUser();
    return currentUser != null;
  }

  Future<void> signIn(AppUser user, {required bool remember}) async {
    currentUser = user;
    await prefs.setSession(user, remember: remember);
  }

  Future<void> signOut() async {
    currentUser = null;
    await prefs.clearSession();
  }

  Future<void> updateLocalProfile(AppUser user) async {
    currentUser = user;
    await prefs.updateUser(user);
  }
}
