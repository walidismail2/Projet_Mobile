import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/reminder_repository.dart';
import 'package:flutter_example/core/services/local_notifications.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/screens/notifications/custom_reminder_screen.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _master = true;
  bool _vaccines = true;
  bool _treatments = true;
  bool _appointments = true;
  bool _meals = true;
  bool _birthdays = true;
  bool _sound = true;
  bool _vibration = true;
  bool _silent = true;
  bool _loading = true;
  List<CustomReminder> _custom = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = Session.instance.prefs;
    _master = await p.getMasterNotifications();
    _vaccines = await p.getReminderEnabled('vaccine');
    _treatments = await p.getReminderEnabled('treatment');
    _appointments = await p.getReminderEnabled('appointment');
    _meals = await p.getReminderEnabled('meal');
    _birthdays = await p.getReminderEnabled('birthday');
    _sound = await p.getBool('sound');
    _vibration = await p.getBool('vibration');
    _silent = await p.getBool('silent_night');
    _custom = await ReminderRepository().getCustomReminders();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = Session.instance.prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            color: AppColors.reminder,
            child: SwitchListTile(
              value: _master,
              onChanged: (v) async {
                setState(() => _master = v);
                await p.setMasterNotifications(v);
                await LocalNotifications.instance.syncForCurrentUser();
              },
              title: const Text('Notifications activées',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: const Text('Alertes sur le téléphone',
                  style: TextStyle(color: Colors.white70)),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Types de rappels'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _vaccines && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _vaccines = v);
                          await p.setReminderEnabled('vaccine', v);
                          await LocalNotifications.instance.syncForCurrentUser();
                        },
                  secondary:
                      const IconBadge(Icons.vaccines, AppColors.health),
                  title: const Text('Vaccins'),
                ),
                SwitchListTile(
                  value: _treatments && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _treatments = v);
                          await p.setReminderEnabled('treatment', v);
                          await LocalNotifications.instance.syncForCurrentUser();
                        },
                  secondary:
                      const IconBadge(Icons.medication, AppColors.primary),
                  title: const Text('Traitements'),
                ),
                SwitchListTile(
                  value: _appointments && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _appointments = v);
                          await p.setReminderEnabled('appointment', v);
                          await LocalNotifications.instance.syncForCurrentUser();
                        },
                  secondary: const IconBadge(Icons.event, AppColors.vet),
                  title: const Text('Rendez-vous'),
                ),
                SwitchListTile(
                  value: _meals && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _meals = v);
                          await p.setReminderEnabled('meal', v);
                          await LocalNotifications.instance.syncForCurrentUser();
                        },
                  secondary:
                      const IconBadge(Icons.restaurant, AppColors.food),
                  title: const Text('Repas'),
                ),
                SwitchListTile(
                  value: _birthdays && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _birthdays = v);
                          await p.setReminderEnabled('birthday', v);
                          await LocalNotifications.instance.syncForCurrentUser();
                        },
                  secondary: const IconBadge(
                      Icons.cake_rounded, Color(0xFFEC4899)),
                  title: const Text('Anniversaires'),
                  subtitle: const Text('Module Animaux · 9h le jour J'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Préférences'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _sound,
                  onChanged: (v) async {
                    setState(() => _sound = v);
                    await p.setBool('sound', v);
                    await LocalNotifications.instance.syncForCurrentUser();
                  },
                  title: const Text('Son'),
                ),
                SwitchListTile(
                  value: _vibration,
                  onChanged: (v) async {
                    setState(() => _vibration = v);
                    await p.setBool('vibration', v);
                    await LocalNotifications.instance.syncForCurrentUser();
                  },
                  title: const Text('Vibration'),
                ),
                SwitchListTile(
                  value: _silent,
                  onChanged: (v) async {
                    setState(() => _silent = v);
                    await p.setBool('silent_night', v);
                    await LocalNotifications.instance.syncForCurrentUser();
                  },
                  title: const Text('Heures calmes 22h–7h'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            'Rappels personnalisés',
            action: '+ Créer',
            onAction: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CustomReminderScreen()),
              );
              await _load();
            },
          ),
          if (_custom.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Aucun rappel personnalisé',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < _custom.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      title: Text(_custom[i].title),
                      subtitle: Text(
                          '${_custom[i].category} · ${_custom[i].date} ${_custom[i].time}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final id = _custom[i].id;
                          if (id == null) return;
                          await ReminderRepository()
                              .deleteCustomReminder(id);
                          await LocalNotifications.instance.cancel(
                              LocalNotifications.customId(id));
                          await _load();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
