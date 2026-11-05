import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'custom_reminder_screen.dart';

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
  bool _sound = true;
  bool _vibration = true;
  bool _silent = true;
  bool _loading = true;

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
    _sound = await p.getBool('sound');
    _vibration = await p.getBool('vibration');
    _silent = await p.getBool('silent_night');
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
              },
              title: const Text('Notifications activées',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: const Text('Préférences locales',
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
                        },
                  secondary:
                      const IconBadge(Icons.medication, AppColors.purple),
                  title: const Text('Traitements'),
                ),
                SwitchListTile(
                  value: _appointments && _master,
                  onChanged: !_master
                      ? null
                      : (v) async {
                          setState(() => _appointments = v);
                          await p.setReminderEnabled('appointment', v);
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
                        },
                  secondary:
                      const IconBadge(Icons.restaurant, AppColors.food),
                  title: const Text('Repas'),
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
                  },
                  title: const Text('Son'),
                ),
                SwitchListTile(
                  value: _vibration,
                  onChanged: (v) async {
                    setState(() => _vibration = v);
                    await p.setBool('vibration', v);
                  },
                  title: const Text('Vibration'),
                ),
                SwitchListTile(
                  value: _silent,
                  onChanged: (v) async {
                    setState(() => _silent = v);
                    await p.setBool('silent_night', v);
                  },
                  title: const Text('Heures calmes 22h–7h'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader('Rappels personnalisés',
              action: '+ Créer',
              onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomReminderScreen()),
                  )),
        ],
      ),
    );
  }
}
