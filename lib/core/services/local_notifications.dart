import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/appointment_repository.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_repository.dart';
import 'package:flutter_example/modules/alimentation/repositories/food_stock_repository.dart';
import 'package:flutter_example/modules/sante/repositories/health_repository.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/modules/compte/repositories/reminder_repository.dart';

/// Notifications système (pas seulement la liste dans l'app).
class LocalNotifications {
  LocalNotifications._();
  static final instance = LocalNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _reminders = ReminderRepository();
  bool _ready = false;

  static int customId(int id) => 100000 + id;
  static int vaccineId(int id) => 200000 + id;
  static int treatmentId(int id) => 300000 + id;
  static int appointmentId(int id) => 400000 + id;
  static int mealId(int id) => 500000 + id;
  static int birthdayId(int petId) => 600000 + petId;
  static int stockId(int id) => 700000 + id;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    final canExact = await androidPlugin?.canScheduleExactNotifications();
    if (canExact == false) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  /// Annule toutes les notifications liées à un animal (avant suppression).
  Future<void> cancelForPet(int petId) async {
    await cancel(birthdayId(petId));
    for (final meal in await FoodRepository().getMeals(petId)) {
      if (meal.id != null) await cancel(mealId(meal.id!));
    }
    for (final stock in await FoodStockRepository().getStocks(petId)) {
      if (stock.id != null) await cancel(stockId(stock.id!));
    }
  }

  /// Alerte « stock bas » à 9h, `alertDays` jours avant que le sac soit vide.
  /// Si le stock est déjà bas, enregistre aussi une alerte dans l'app.
  Future<void> scheduleFoodStock(
    FoodStock stock, {
    required String petName,
    bool recordInApp = false,
  }) async {
    final id = stock.id;
    if (id == null) return;
    await cancel(stockId(id));
    if (stock.dailyGrams <= 0) return;
    final days = stock.daysLeft();
    if (stock.isLow()) {
      if (recordInApp) {
        await _inbox(
          title: 'Stock bas 🛒',
          message: days == 0
              ? '${stock.name} de $petName est épuisé.'
              : '${stock.name} de $petName : plus que $days jour(s).',
          type: NotificationType.meal,
          petId: stock.petId,
        );
      }
      return;
    }
    await _schedule(
      notificationId: stockId(id),
      type: NotificationType.meal,
      title: 'Stock bas 🛒',
      body: '${stock.name} de $petName : plus que ${stock.alertDays} jour(s).',
      when: stock.alertDate,
    );
  }

  Future<void> scheduleVaccine({
    required int id,
    required String name,
    required String nextDate,
    bool recordInApp = false,
  }) async {
    final when = _atTime(parseFrDate(nextDate), 9, 0);
    await _schedule(
      notificationId: vaccineId(id),
      type: NotificationType.vaccine,
      title: 'Rappel vaccin',
      body: '$name · $nextDate',
      when: when,
      soonIfPast: recordInApp,
    );
    if (recordInApp) {
      await _inbox(
        title: 'Rappel vaccin',
        message: '$name le $nextDate',
        type: NotificationType.vaccine,
      );
    }
  }

  Future<void> scheduleTreatment({
    required int id,
    required String name,
    required String dosage,
    required bool active,
    bool recordInApp = false,
  }) async {
    if (!active) {
      await cancel(treatmentId(id));
      return;
    }
    final now = DateTime.now();
    await _schedule(
      notificationId: treatmentId(id),
      type: NotificationType.treatment,
      title: 'Traitement',
      body: '$name · $dosage',
      when: DateTime(now.year, now.month, now.day, 9, 0),
      repeat: DateTimeComponents.time,
    );
    if (recordInApp) {
      await _inbox(
        title: 'Traitement',
        message: '$name · $dosage, chaque jour à 9h',
        type: NotificationType.treatment,
      );
    }
  }

  /// Repas quotidien (`date == null`) : chaque jour à l'heure.
  /// Repas ponctuel : une seule fois, ce jour-là (rien si déjà passé).
  Future<void> scheduleMeal({
    required int id,
    required String name,
    required String time,
    DateTime? date,
    bool recordInApp = false,
  }) async {
    await cancel(mealId(id));
    final (h, m) = _hm(time);
    final day = date ?? DateTime.now();
    await _schedule(
      notificationId: mealId(id),
      type: NotificationType.meal,
      title: 'Repas',
      body: '$name · $time',
      when: DateTime(day.year, day.month, day.day, h, m),
      repeat: date == null ? DateTimeComponents.time : null,
    );
    if (recordInApp) {
      await _inbox(
        title: 'Repas',
        message: date == null
            ? '$name à $time, tous les jours'
            : '$name le ${formatFrDate(date)} à $time',
        type: NotificationType.meal,
      );
    }
  }

  Future<void> scheduleAppointment(
    Appointment appointment, {
    bool recordInApp = false,
  }) async {
    final id = appointment.id;
    if (id == null) return;
    if (appointment.status != AppointmentStatus.upcoming) {
      await cancel(appointmentId(id));
      return;
    }
    await _schedule(
      notificationId: appointmentId(id),
      type: NotificationType.appointment,
      title: 'Rendez-vous',
      body: '${appointment.reason} · ${appointment.time}',
      when: _appointmentWhen(appointment),
      soonIfPast: recordInApp,
    );
    if (recordInApp) {
      await _inbox(
        title: 'Rendez-vous',
        message: '${appointment.reason} · ${appointment.date} à ${appointment.time}',
        type: NotificationType.appointment,
      );
    }
  }

  /// Anniversaire animal (module Animaux) — chaque année à 9h.
  Future<void> scheduleBirthday({
    required Pet pet,
    bool recordInApp = false,
  }) async {
    final id = pet.id;
    if (id == null) return;
    final birth = parseFrDate(pet.birthDate);
    if (birth == null) {
      await cancel(birthdayId(id));
      return;
    }
    final now = DateTime.now();
    var next = DateTime(now.year, birth.month, birth.day, 9, 0);
    if (!next.isAfter(now)) {
      next = DateTime(now.year + 1, birth.month, birth.day, 9, 0);
    }
    await _schedule(
      notificationId: birthdayId(id),
      type: NotificationType.birthday,
      title: 'Anniversaire 🎂',
      body: '${pet.emoji} ${pet.name} fête ses ${Pet.ageFromBirthDate(pet.birthDate, next)} !',
      when: next,
      repeat: DateTimeComponents.dateAndTime,
    );
    if (recordInApp) {
      await _inbox(
        title: 'Anniversaire programmé',
        message:
            '${pet.name} · rappel le ${birth.day.toString().padLeft(2, '0')}/${birth.month.toString().padLeft(2, '0')} à 9h',
        type: NotificationType.birthday,
      );
    }
  }

  Future<void> scheduleCustom(
    CustomReminder reminder, {
    bool soonIfPast = false,
  }) async {
    final id = reminder.id;
    if (id == null) return;
    final (h, m) = _hm(reminder.time);
    final repeat = switch (reminder.repeat) {
      'Quotidien' => DateTimeComponents.time,
      'Hebdo' => DateTimeComponents.dayOfWeekAndTime,
      'Mensuel' => DateTimeComponents.dayOfMonthAndTime,
      _ => null,
    };
    await _schedule(
      notificationId: customId(id),
      type: NotificationType.custom,
      title: reminder.title,
      body: reminder.note.trim().isEmpty
          ? '${reminder.category} · ${reminder.time}'
          : reminder.note.trim(),
      when: _atTime(parseFrDate(reminder.date), h, m),
      repeat: repeat,
      soonIfPast: soonIfPast,
      customIgnoresTypeSwitch: true,
    );
  }

  /// Reprogramme tout depuis SQLite selon les interrupteurs.
  Future<void> syncForCurrentUser() async {
    if (!_ready) return;
    await _plugin.cancelAllPendingNotifications();
    final prefs = Session.instance.prefs;
    if (!await prefs.getMasterNotifications()) return;

    final ownerId = Session.instance.userId;
    if (ownerId == null) return;
    final pets = await PetRepository().getByOwner(ownerId);
    final health = HealthRepository();
    final food = FoodRepository();
    for (final pet in pets) {
      final petId = pet.id;
      if (petId == null) continue;
      await scheduleBirthday(pet: pet);
      for (final vaccine in await health.getVaccines(petId)) {
        final id = vaccine.id;
        if (id == null) continue;
        await scheduleVaccine(
          id: id,
          name: vaccine.name,
          nextDate: vaccine.nextDate,
        );
      }
      for (final treatment in await health.getTreatments(petId)) {
        final id = treatment.id;
        if (id == null) continue;
        await scheduleTreatment(
          id: id,
          name: treatment.name,
          dosage: treatment.dosage,
          active: !treatment.isCompleted,
        );
      }
      for (final meal in await food.getMeals(petId)) {
        final id = meal.id;
        if (id == null) continue;
        await scheduleMeal(
          id: id,
          name: meal.name,
          time: meal.time,
          date: meal.date,
        );
      }
      for (final stock in await FoodStockRepository().getStocks(petId)) {
        await scheduleFoodStock(stock, petName: pet.name);
      }
    }
    for (final appointment in await AppointmentRepository().getAll()) {
      await scheduleAppointment(appointment);
    }
    for (final reminder in await _reminders.getCustomReminders()) {
      await scheduleCustom(reminder);
    }
  }

  Future<void> _schedule({
    required int notificationId,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime? when,
    DateTimeComponents? repeat,
    bool soonIfPast = false,
    bool customIgnoresTypeSwitch = false,
  }) async {
    if (!_ready || when == null) return;
    final prefs = Session.instance.prefs;
    if (!await prefs.getMasterNotifications()) return;
    if (!customIgnoresTypeSwitch &&
        !await prefs.getReminderEnabled(type.name)) {
      return;
    }

    final quiet = await prefs.getBool('silent_night');
    final adjusted = _respectQuiet(when, quiet);
    final next = _nextOccurrence(
      adjusted,
      repeat,
      soonIfPast: soonIfPast,
    );
    if (next == null) return;

    final details = await _details();
    final scheduled = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
      next.second,
    );
    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeat,
      );
    } catch (e) {
      debugPrint('Exact schedule failed, fallback inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: repeat,
        );
      } catch (e2) {
        debugPrint('Notification not scheduled: $e2');
      }
    }
  }

  Future<NotificationDetails> _details() async {
    final prefs = Session.instance.prefs;
    final sound = await prefs.getBool('sound');
    final vibration = await prefs.getBool('vibration');
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'petcare_${sound}_$vibration',
        'Rappels PetCare',
        channelDescription: 'Vaccins, traitements, repas et rendez-vous',
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibration,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: sound,
        presentBadge: true,
      ),
    );
  }

  Future<void> _inbox({
    required String title,
    required String message,
    required NotificationType type,
    int? petId,
  }) async {
    await _reminders.insertNotification(AppNotification(
      petId: petId,
      title: title,
      message: message,
      time: "À l'instant",
      type: type,
      unread: true,
    ));
  }

  DateTime? _atTime(DateTime? day, int hour, int minute) {
    if (day == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  (int, int) _hm(String raw) {
    final parts = raw.trim().split(RegExp(r'[:hH]'));
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return (hour.clamp(0, 23), minute.clamp(0, 59));
  }

  DateTime? _appointmentWhen(Appointment appointment) {
    const months = {
      'janvier': 1,
      'février': 2,
      'fevrier': 2,
      'mars': 3,
      'avril': 4,
      'mai': 5,
      'juin': 6,
      'juillet': 7,
      'août': 8,
      'aout': 8,
      'septembre': 9,
      'octobre': 10,
      'novembre': 11,
      'décembre': 12,
      'decembre': 12,
    };
    final lower = appointment.date.toLowerCase();
    int? month;
    for (final entry in months.entries) {
      if (lower.contains(entry.key)) {
        month = entry.value;
        break;
      }
    }
    final dayMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(appointment.date);
    if (month == null || dayMatch == null) return null;
    final day = int.parse(dayMatch.group(1)!);
    final (hour, minute) = _hm(appointment.time);
    final slot = DateTime(DateTime.now().year, month, day, hour, minute);
    return slot.subtract(const Duration(hours: 1));
  }

  DateTime _respectQuiet(DateTime when, bool quiet) {
    if (!quiet) return when;
    if (when.hour >= 22) {
      return DateTime(when.year, when.month, when.day + 1, 8);
    }
    if (when.hour < 7) {
      return DateTime(when.year, when.month, when.day, 8);
    }
    return when;
  }

  DateTime? _nextOccurrence(
    DateTime when,
    DateTimeComponents? repeat, {
    required bool soonIfPast,
  }) {
    if (when.isAfter(DateTime.now())) return when;
    if (repeat == null) {
      return soonIfPast ? DateTime.now().add(const Duration(seconds: 20)) : null;
    }
    var cursor = when;
    for (var i = 0; i < 400 && !cursor.isAfter(DateTime.now()); i++) {
      cursor = switch (repeat) {
        DateTimeComponents.time => cursor.add(const Duration(days: 1)),
        DateTimeComponents.dayOfWeekAndTime =>
          cursor.add(const Duration(days: 7)),
        DateTimeComponents.dayOfMonthAndTime => DateTime(
            cursor.year,
            cursor.month + 1,
            cursor.day,
            cursor.hour,
            cursor.minute,
          ),
        DateTimeComponents.dateAndTime => DateTime(
            cursor.year + 1,
            cursor.month,
            cursor.day,
            cursor.hour,
            cursor.minute,
          ),
      };
    }
    return cursor.isAfter(DateTime.now()) ? cursor : null;
  }
}
