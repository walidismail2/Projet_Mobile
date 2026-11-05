import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../auth/welcome_screen.dart';
import '../notifications/reminder_settings_screen.dart';
import 'edit_profile_screen.dart';

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
    _pets = PetRepository().getByOwner(Session.instance.userId!);
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.currentUser!;
    final initials = () {
      final p = user.name.trim().split(RegExp(r'\s+'));
      if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
      return user.name.isEmpty ? '?' : user.name[0].toUpperCase();
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
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
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(initials,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email),
                    const SizedBox(height: 12),
                    Text('${pets.length} animaux',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                        if (mounted) setState(() {});
                      },
                    ),
                    ListTile(
                      leading: const IconBadge(Icons.notifications_none,
                          AppColors.reminder),
                      title: const Text('Notifications & rappels'),
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
