import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'custom_reminder_screen.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _all = true;
  final Map<NotificationType, bool> _enabled = {
    for (final t in NotificationType.values) t: true,
  };
  final Map<NotificationType, String> _timing = {
    NotificationType.vaccine: '7 jours avant',
    NotificationType.treatment: 'À l\'heure de la prise',
    NotificationType.appointment: '24 h avant',
    NotificationType.meal: 'À l\'heure du repas',
    NotificationType.custom: 'Selon le rappel',
  };
  bool _sound = true;
  bool _vibration = true;
  bool _silentNight = false;

  static const _timingOptions = {
    NotificationType.vaccine: ['1 jour avant', '3 jours avant', '7 jours avant', '1 mois avant'],
    NotificationType.treatment: ['À l\'heure de la prise', '15 min avant', '30 min avant'],
    NotificationType.appointment: ['1 h avant', '3 h avant', '24 h avant', '48 h avant'],
    NotificationType.meal: ['À l\'heure du repas', '10 min avant', '30 min avant'],
  };

  void _pickTiming(NotificationType type) {
    final options = _timingOptions[type];
    if (options == null) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rappel ${type.label.toLowerCase()}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(o,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
                trailing: _timing[type] == o
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _timing[type] = o);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels & notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A8F), AppColors.reminder]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text('Activer tous les rappels',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Switch(
                  value: _all,
                  trackColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white24),
                  onChanged: (v) => setState(() => _all = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Types de rappels'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final t in NotificationType.values)
                  ListTile(
                    onTap: () => _pickTiming(t),
                    leading: IconBadge(t.icon, t.color, size: 42),
                    title: Text('Rappel ${t.label.toLowerCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    subtitle: Text(_timing[t]!),
                    trailing: Switch(
                      value: _all && _enabled[t]!,
                      onChanged: _all
                          ? (v) => setState(() => _enabled[t] = v)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            'Rappels personnalisés',
            action: '+ Créer',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomReminderScreen()),
            ),
          ),
          const _CustomReminderTile(
            emoji: '✨',
            title: 'Brossage de Luna',
            subtitle: 'Chaque samedi · 10:00',
          ),
          const _CustomReminderTile(
            emoji: '🛁',
            title: 'Bain de Rocky',
            subtitle: 'Tous les mois · le 1er · 18:00',
          ),
          const _CustomReminderTile(
            emoji: '🥕',
            title: 'Acheter du foin pour Coco',
            subtitle: 'Toutes les 2 semaines · 09:00',
          ),
          const SizedBox(height: 24),
          const SectionHeader('Préférences'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: _sound,
                  onChanged: (v) => setState(() => _sound = v),
                  secondary: const Icon(Icons.volume_up_rounded,
                      color: AppColors.textSecondary),
                  title: const Text('Son',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.navy)),
                ),
                SwitchListTile(
                  value: _vibration,
                  onChanged: (v) => setState(() => _vibration = v),
                  secondary: const Icon(Icons.vibration_rounded,
                      color: AppColors.textSecondary),
                  title: const Text('Vibration',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.navy)),
                ),
                SwitchListTile(
                  value: _silentNight,
                  onChanged: (v) => setState(() => _silentNight = v),
                  secondary: const Icon(Icons.bedtime_rounded,
                      color: AppColors.textSecondary),
                  title: const Text('Mode silencieux la nuit',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.navy)),
                  subtitle: const Text('22:00 – 07:00'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomReminderTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _CustomReminderTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomReminderScreen()),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.reminder.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.navy)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
