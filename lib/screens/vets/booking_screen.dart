import 'package:flutter/material.dart';

import '../../data/app_refresh.dart';
import '../../data/session.dart';
import '../../models/models.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../services/local_notifications.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class BookingScreen extends StatefulWidget {
  final Vet vet;
  final Appointment? existing;

  const BookingScreen({super.key, required this.vet, this.existing});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _days = [
    ('Mer', '30'),
    ('Jeu', '01'),
    ('Ven', '02'),
    ('Sam', '03'),
    ('Lun', '05'),
    ('Mar', '06'),
  ];
  static const _slots = [
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '14:00',
    '14:30',
    '15:00',
    '16:00',
    '17:30',
    '18:00'
  ];
  static const _unavailable = {'09:00', '10:00', '15:00', '17:30'};
  static const _reasons = ['Consultation', 'Vaccination', 'Contrôle', 'Urgence'];

  final _petsRepo = PetRepository();
  final _apptRepo = AppointmentRepository();
  List<Pet> _pets = [];
  int _pet = 0;
  int _day = 2;
  String _time = '10:30';
  String _reason = 'Vaccination';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pets = await _petsRepo.getByOwner(Session.instance.userId!);
    if (mounted) {
      setState(() {
        _pets = pets;
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_pets.isEmpty) {
      showSuccessSnack(context, 'Ajoutez d\'abord un animal');
      return;
    }
    final pet = _pets[_pet];
    final appointment = Appointment(
      vetId: widget.vet.id,
      petId: pet.id!,
      date: '${_days[_day].$1} ${_days[_day].$2} octobre',
      day: _days[_day].$2,
      month: 'OCT',
      time: _time,
      reason: _reason,
      status: AppointmentStatus.upcoming,
    );
    final appointmentId = await _apptRepo.insert(appointment);
    await LocalNotifications.instance.scheduleAppointment(
      Appointment(
        id: appointmentId,
        vetId: appointment.vetId,
        petId: appointment.petId,
        date: appointment.date,
        day: appointment.day,
        month: appointment.month,
        time: appointment.time,
        reason: appointment.reason,
        status: appointment.status,
      ),
      recordInApp: true,
    );
    AppRefresh.instance.appointmentsChanged();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.health, size: 64),
              const SizedBox(height: 12),
              Text('Rendez-vous confirmé !',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${pet.name} · ${widget.vet.name}\n${_days[_day].$1} ${_days[_day].$2} à $_time',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Parfait !'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre rendez-vous')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _confirm,
            child: const Text('Confirmer le rendez-vous'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                VetAvatar(widget.vet, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.vet.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(widget.vet.clinic),
                    ],
                  ),
                ),
                Text(widget.vet.price,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Animal', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          PetSelector(
              pets: _pets,
              selected: _pet,
              onChanged: (i) => setState(() => _pet = i)),
          const SizedBox(height: 16),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _day == i;
                return GestureDetector(
                  onTap: () => setState(() => _day = i),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_days[i].$1,
                            style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary)),
                        Text(_days[i].$2,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: sel ? Colors.white : AppColors.navy)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Créneau', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _slots)
                ChoiceChip(
                  label: Text(s),
                  selected: _time == s,
                  onSelected: _unavailable.contains(s)
                      ? null
                      : (_) => setState(() => _time = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Motif', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final r in _reasons)
                ChoiceChip(
                  label: Text(r),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
