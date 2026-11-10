import 'package:flutter/foundation.dart';

/// Notifie les écrans (accueil, santé, repas…) quand les données locales changent.
class AppRefresh extends ChangeNotifier {
  AppRefresh._();
  static final AppRefresh instance = AppRefresh._();

  void petsChanged() => notifyListeners();

  void appointmentsChanged() => notifyListeners();

  void healthChanged() => notifyListeners();
}
