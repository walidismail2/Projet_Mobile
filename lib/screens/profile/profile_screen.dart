import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../auth/welcome_screen.dart';
import '../notifications/reminder_settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primaryLight,
                      child: Text('SB',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(MockData.ownerName, style: text.titleLarge),
                Text(MockData.ownerEmail, style: text.bodyMedium),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Stat(value: '${MockData.pets.length}', label: 'Animaux'),
                    _divider(),
                    const _Stat(value: '12', label: 'Rendez-vous'),
                    _divider(),
                    const _Stat(value: '8', label: 'Vaccins'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Mes animaux'),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final pet in MockData.pets) ...[
                  PetAvatar(pet, size: 60),
                  const SizedBox(width: 10),
                ],
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Compte'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  color: AppColors.primary,
                  title: 'Informations personnelles',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                ),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  color: AppColors.reminder,
                  title: 'Notifications & rappels',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReminderSettingsScreen()),
                  ),
                ),
                const _MenuTile(
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.vet,
                  title: 'Sécurité & mot de passe',
                ),
                const _MenuTile(
                  icon: Icons.language_rounded,
                  color: AppColors.health,
                  title: 'Langue',
                  trailing: 'Français',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Assistance'),
          const AppCard(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.food,
                  title: 'Centre d\'aide',
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  color: AppColors.purple,
                  title: 'Confidentialité',
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
                message: 'Vous devrez vous reconnecter pour accéder à vos données.',
                confirmLabel: 'Déconnexion',
                icon: Icons.logout_rounded,
              );
              if (ok && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.border);
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: IconBadge(icon, color, size: 40),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.navy)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: Theme.of(context).textTheme.bodyMedium),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
