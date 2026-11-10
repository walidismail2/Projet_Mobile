import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/modules/compte/screens/auth/welcome_screen.dart';
import 'package:flutter_example/core/shell/main_shell.dart';
import 'package:flutter_example/modules/compte/screens/vet_role/vet_shell.dart';
import 'package:flutter_example/modules/compte/repositories/auth_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  await AuthRepository().ensureAdminSeeded();
  await LocalNotifications.instance.init();
  final loggedIn = await Session.instance.restore();
  if (loggedIn) {
    await LocalNotifications.instance.syncForCurrentUser();
  }
  runApp(PetCareApp(startLoggedIn: loggedIn));
}

class PetCareApp extends StatelessWidget {
  final bool startLoggedIn;

  const PetCareApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    final home = !startLoggedIn
        ? const WelcomeScreen()
        : (Session.instance.currentUser?.isVet == true
            ? const VetShell()
            : const MainShell());

    return MaterialApp(
      title: 'PetCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home,
    );
  }
}
