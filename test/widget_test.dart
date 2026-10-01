import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_example/data/mock_data.dart';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/screens/auth/login_screen.dart';
import 'package:flutter_example/screens/auth/register_screen.dart';
import 'package:flutter_example/screens/food/add_meal_screen.dart';
import 'package:flutter_example/screens/food/diet_form_screen.dart';
import 'package:flutter_example/screens/health/add_health_record_screen.dart';
import 'package:flutter_example/screens/main_shell.dart';
import 'package:flutter_example/screens/notifications/custom_reminder_screen.dart';
import 'package:flutter_example/screens/notifications/notifications_screen.dart';
import 'package:flutter_example/screens/notifications/reminder_settings_screen.dart';
import 'package:flutter_example/screens/pets/pet_detail_screen.dart';
import 'package:flutter_example/screens/pets/pet_form_screen.dart';
import 'package:flutter_example/screens/profile/edit_profile_screen.dart';
import 'package:flutter_example/screens/profile/profile_screen.dart';
import 'package:flutter_example/screens/vets/booking_screen.dart';
import 'package:flutter_example/screens/vets/vet_profile_screen.dart';
import 'package:flutter_example/screens/vets/vet_search_screen.dart';

void main() {
  testWidgets('Welcome screen shows PetCare branding', (tester) async {
    await tester.pumpWidget(const PetCareApp());

    expect(find.text('PetCare'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('Main shell navigates between all tabs', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    expect(find.text('Bonjour Sarah 👋'), findsOneWidget);

    for (final label in ['Animaux', 'Santé', 'RDV', 'Repas', 'Accueil']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'profile': const ProfileScreen(),
    'edit profile': const EditProfileScreen(),
    'pet detail': PetDetailScreen(pet: MockData.pets.first),
    'pet form (add)': const PetFormScreen(),
    'pet form (edit)': PetFormScreen(pet: MockData.pets.first),
    for (final type in HealthRecordType.values)
      'health record ${type.name}': AddHealthRecordScreen(type: type),
    'vet search': const VetSearchScreen(),
    'vet profile': VetProfileScreen(vet: MockData.vets.first),
    'booking': BookingScreen(vet: MockData.vets.first),
    'add meal': const AddMealScreen(),
    'diet form': const DietFormScreen(),
    'notifications': const NotificationsScreen(),
    'reminder settings': const ReminderSettingsScreen(),
    'custom reminder': const CustomReminderScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} screen renders without layout errors',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
