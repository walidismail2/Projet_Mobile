import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'custom_reminder_screen.dart';
import 'reminder_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType? _filter;

  @override
  Widget build(BuildContext context) {
    final items = MockData.notifications
        .where((n) => _filter == null || n.type == _filter)
        .toList();
    final today = items.where((n) => n.time.startsWith('Il y a')).toList();
    final earlier = items.where((n) => !n.time.startsWith('Il y a')).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Réglages des rappels',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomReminderScreen()),
        ),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Nouveau rappel',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ChoiceChip(
                  label: const Text('Toutes'),
                  selected: _filter == null,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final t in NotificationType.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(t.icon,
                        size: 18,
                        color: _filter == t ? Colors.white : t.color),
                    label: Text(t.label),
                    selected: _filter == t,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = t),
                  ),
                ],
              ],
            ),
          ),
          if (today.isNotEmpty) ...[
            _header('Aujourd\'hui', action: 'Tout marquer comme lu'),
            for (final n in today) _NotificationTile(n),
          ],
          if (earlier.isNotEmpty) ...[
            _header('Plus tôt'),
            for (final n in earlier) _NotificationTile(n),
          ],
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Text('🔕', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 12),
                  Text('Aucune notification',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(String title, {String? action}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: SectionHeader(title, action: action, onAction: () {}),
      );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;

  const _NotificationTile(this.n);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Dismissible(
        key: ValueKey(n.title + n.time),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.reminder,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: AppCard(
          color: n.unread ? const Color(0xFFFFF6F1) : Colors.white,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(n.type.icon, n.type.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.title,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Text(n.time,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(height: 1.35)),
                    if (n.type == NotificationType.treatment ||
                        n.type == NotificationType.meal) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SmallAction('Fait', AppColors.health,
                              Icons.check_rounded),
                          _SmallAction('Reporter 15 min',
                              AppColors.textSecondary, Icons.snooze_rounded),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (n.unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SmallAction(this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: StatusPill(label, color, icon: icon),
    );
  }
}
