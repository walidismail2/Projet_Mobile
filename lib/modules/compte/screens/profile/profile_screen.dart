import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/auth_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/screens/appointments/appointments_screen.dart';
import 'package:flutter_example/modules/compte/screens/auth/welcome_screen.dart';
import 'package:flutter_example/modules/compte/screens/notifications/notifications_screen.dart';
import 'package:flutter_example/modules/compte/screens/notifications/reminder_settings_screen.dart';
import 'package:flutter_example/modules/compte/screens/vets/vet_search_screen.dart';
import 'package:flutter_example/modules/compte/screens/profile/change_password_screen.dart';
import 'package:flutter_example/modules/compte/screens/profile/edit_profile_screen.dart';

/// Module 4 — Compte / User (profil, RDV, vétos, notifications).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Pet>> _pets;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final id = Session.instance.userId;
    _pets = id == null
        ? Future.value(const <Pet>[])
        : PetRepository().getByOwner(id);
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Compte')),
      body: FutureBuilder<List<Pet>>(
        future: _pets,
        builder: (context, snap) {
          final pets = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                child: Column(
                  children: [
                    UserAvatar(user, size: 92, bordered: true),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user.phone,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 12),
                    StatusPill(
                      user.roleLabel,
                      user.isAdmin
                          ? AppColors.reminder
                          : user.isVet
                              ? AppColors.vet
                              : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pets.length} animal${pets.length > 1 ? 'aux' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Rendez-vous & vétérinaires'),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const IconBadge(
                          Icons.calendar_month_rounded, AppColors.vet),
                      title: const Text('Mes rendez-vous'),
                      subtitle: const Text('Liste et suivi des RDV'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const IconBadge(Icons.search_rounded, AppColors.vet),
                      title: const Text('Trouver un vétérinaire'),
                      subtitle: const Text('Annuaire et prise de RDV'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VetSearchScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Mon compte'),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const IconBadge(
                          Icons.person_outline, AppColors.primary),
                      title: const Text('Informations personnelles'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        );
                        if (mounted) setState(_reload);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBadge(
                          Icons.lock_outline_rounded, AppColors.navy),
                      title: const Text('Modifier le mot de passe'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBadge(
                          Icons.notifications_none, AppColors.reminder),
                      title: const Text('Notifications'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBadge(
                          Icons.settings_outlined, AppColors.primary),
                      title: const Text('Rappels & préférences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReminderSettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.reminder,
                  side: const BorderSide(color: AppColors.reminder),
                ),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Se déconnecter ?',
                    message: 'Vous devrez vous reconnecter.',
                    confirmLabel: 'Déconnexion',
                  );
                  if (ok && context.mounted) {
                    await AuthRepository().logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WelcomeScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      ),
    );
  }
}
