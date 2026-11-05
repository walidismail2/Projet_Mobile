import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/session.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/main_shell.dart';
import 'screens/vet/vet_shell.dart';
import 'services/local_notifications.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const _FirebaseSetupApp());
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppDatabase.instance.database;
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

class _FirebaseSetupApp extends StatelessWidget {
  const _FirebaseSetupApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase non configuré',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Crée un projet sur console.firebase.google.com\n'
                  '2. Active Authentication → E-mail/mot de passe\n'
                  '3. Crée une base Firestore\n'
                  '4. Lance : dart pub global activate flutterfire_cli\n'
                  '5. Puis : flutterfire configure\n'
                  '6. Relance flutter run\n\n'
                  'Détails dans README.md (section Firebase).',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
