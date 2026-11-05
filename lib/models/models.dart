import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum UserRole { owner, vet }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.owner,
  });

  bool get isVet => role == UserRole.vet;

  factory AppUser.fromApi(Map<String, dynamic> json) => AppUser(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: (json['username'] ?? json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        role: (json['role']?.toString() == 'vet')
            ? UserRole.vet
            : UserRole.owner,
      );

  Map<String, Object?> toPrefsMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
      };

  factory AppUser.fromPrefsMap(Map<String, String> m) => AppUser(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] == 'vet' ? UserRole.vet : UserRole.owner,
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
      );
}

/// Identifiant Firestore d'un animal : `{ownerId}_{localPetId}`.
String cloudPetId(String ownerId, int localPetId) => '${ownerId}_$localPetId';

class Pet {
  final int? id;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final String age;
  final double weight;
  final String sex;
  final String emoji;
  final Color color;
  final String birthDate;
  final String chip;
  final bool sterilized;
  final String? photoPath;

  const Pet({
    this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
    required this.sex,
    required this.emoji,
    required this.color,
    required this.birthDate,
    required this.chip,
    required this.sterilized,
    this.photoPath,
  });

  /// Âge calculé depuis `birthDate` (format JJ/MM/AAAA).
  String get computedAge => ageFromBirthDate(birthDate);

  static String ageFromBirthDate(String birthDate, [DateTime? now]) {
    final parts = birthDate.trim().split('/');
    if (parts.length != 3) return '—';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return '—';
    DateTime birth;
    try {
      birth = DateTime(year, month, day);
    } catch (_) {
      return '—';
    }
    final today = now ?? DateTime.now();
    if (birth.isAfter(today)) return '—';

    var years = today.year - birth.year;
    var months = today.month - birth.month;
    if (today.day < birth.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years <= 0) {
      if (months <= 0) return 'Nouveau-né';
      return months == 1 ? '1 mois' : '$months mois';
    }
    if (months == 0) {
      return years == 1 ? '1 an' : '$years ans';
    }
    final y = years == 1 ? '1 an' : '$years ans';
    final m = months == 1 ? '1 mois' : '$months mois';
    return '$y $m';
  }

  Pet copyWith({
    int? id,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    String? age,
    double? weight,
    String? sex,
    String? emoji,
    Color? color,
    String? birthDate,
    String? chip,
    bool? sterilized,
    String? photoPath,
  }) =>
      Pet(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        species: species ?? this.species,
        breed: breed ?? this.breed,
        age: age ?? this.age,
        weight: weight ?? this.weight,
        sex: sex ?? this.sex,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        birthDate: birthDate ?? this.birthDate,
        chip: chip ?? this.chip,
        sterilized: sterilized ?? this.sterilized,
        photoPath: photoPath ?? this.photoPath,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'weight': weight,
        'sex': sex,
        'emoji': emoji,
        'color_hex': color.toARGB32(),
        'birth_date': birthDate,
        'chip': chip,
        'sterilized': sterilized ? 1 : 0,
        'photo_path': photoPath,
      };

  factory Pet.fromMap(Map<String, Object?> m) => Pet(
        id: m['id'] as int?,
        ownerId: m['owner_id'] as String,
        name: m['name'] as String,
        species: m['species'] as String,
        breed: m['breed'] as String,
        age: m['age'] as String,
        weight: (m['weight'] as num).toDouble(),
        sex: m['sex'] as String,
        emoji: m['emoji'] as String,
        color: Color(m['color_hex'] as int),
        birthDate: m['birth_date'] as String,
        chip: m['chip'] as String,
        sterilized: (m['sterilized'] as int) == 1,
        photoPath: m['photo_path'] as String?,
      );
}

enum HealthStatus { upToDate, soon, late }

extension HealthStatusX on HealthStatus {
  String get label => switch (this) {
        HealthStatus.upToDate => 'À jour',
        HealthStatus.soon => 'Bientôt',
        HealthStatus.late => 'En retard',
      };
}

/// Parse une date `JJ/MM/AAAA` (null si invalide).
DateTime? parseFrDate(String raw) {
  final p = raw.trim().split('/');
  if (p.length != 3) return null;
  final d = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final y = int.tryParse(p[2]);
  if (d == null || m == null || y == null) return null;
  try {
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

String formatFrDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Statut vaccin selon la date du prochain rappel.
HealthStatus healthStatusFromNextDate(String nextDate) {
  final next = parseFrDate(nextDate);
  if (next == null) return HealthStatus.upToDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = next.difference(today).inDays;
  if (diff < 0) return HealthStatus.late;
  if (diff <= 30) return HealthStatus.soon;
  return HealthStatus.upToDate;
}

class Vaccine {
  final int? id;
  final int petId;
  final String name;
  final String date;
  final String nextDate;
  final String vet;
  final HealthStatus status;

  const Vaccine({
    this.id,
    required this.petId,
    required this.name,
    required this.date,
    required this.nextDate,
    required this.vet,
    required this.status,
  });

  Vaccine withComputedStatus() => Vaccine(
        id: id,
        petId: petId,
        name: name,
        date: date,
        nextDate: nextDate,
        vet: vet,
        status: healthStatusFromNextDate(nextDate),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'date': date,
        'next_date': nextDate,
        'vet': vet,
        'status': status.name,
      };

  factory Vaccine.fromMap(Map<String, Object?> m) {
    final next = m['next_date'] as String;
    return Vaccine(
      id: m['id'] as int?,
      petId: m['pet_id'] as int,
      name: m['name'] as String,
      date: m['date'] as String,
      nextDate: next,
      vet: m['vet'] as String,
      status: healthStatusFromNextDate(next),
    );
  }
}

class Treatment {
  final int? id;
  final int petId;
  final String name;
  final String dosage;
  final String frequency;
  final int currentDay;
  final int totalDays;
  final IconData icon;

  Treatment({
    this.id,
    required this.petId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.currentDay,
    required this.totalDays,
    required this.icon,
  });

  bool get isCompleted => currentDay >= totalDays;
  double get progress =>
      totalDays <= 0 ? 0 : (currentDay / totalDays).clamp(0.0, 1.0);

  Treatment copyWith({int? currentDay}) => Treatment(
        id: id,
        petId: petId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        currentDay: currentDay ?? this.currentDay,
        totalDays: totalDays,
        icon: icon,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'current_day': currentDay,
        'total_days': totalDays,
        'icon_code': icon.codePoint,
      };

  factory Treatment.fromMap(Map<String, Object?> m) => Treatment(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        name: m['name'] as String,
        dosage: m['dosage'] as String,
        frequency: m['frequency'] as String,
        currentDay: m['current_day'] as int,
        totalDays: m['total_days'] as int,
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
      );
}

class MedicalEvent {
  final int? id;
  final int petId;
  final String title;
  final String date;
  final String description;
  final IconData icon;
  final Color color;

  MedicalEvent({
    this.id,
    required this.petId,
    required this.title,
    required this.date,
    required this.description,
    required this.icon,
    required this.color,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'title': title,
        'date': date,
        'description': description,
        'icon_code': icon.codePoint,
        'color_hex': color.toARGB32(),
      };

  factory MedicalEvent.fromMap(Map<String, Object?> m) => MedicalEvent(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        title: m['title'] as String,
        date: m['date'] as String,
        description: m['description'] as String,
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
        color: Color(m['color_hex'] as int),
      );
}

class MedicalDocument {
  final int? id;
  final int petId;
  final String name;
  final String date;
  final String size;
  final bool isPdf;
  final String? filePath;

  const MedicalDocument({
    this.id,
    required this.petId,
    required this.name,
    required this.date,
    required this.size,
    required this.isPdf,
    this.filePath,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'date': date,
        'size': size,
        'is_pdf': isPdf ? 1 : 0,
        'file_path': filePath,
      };

  factory MedicalDocument.fromMap(Map<String, Object?> m) => MedicalDocument(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        name: m['name'] as String,
        date: m['date'] as String,
        size: m['size'] as String,
        isPdf: (m['is_pdf'] as int) == 1,
        filePath: m['file_path'] as String?,
      );
}

class Vet {
  final String id;
  final String name;
  final String specialty;
  final String clinic;
  final String address;
  final double rating;
  final int reviews;
  final String distance;
  final int experience;
  final bool availableToday;
  final Color color;
  final String price;
  final String image;
  final List<String> services;
  final String hoursWeekdays;
  final String hoursSaturday;
  final String phone;

  const Vet({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.experience,
    required this.availableToday,
    required this.color,
    required this.price,
    this.image = '',
    this.services = const [
      'Consultation',
      'Vaccination',
      'Chirurgie',
      'Radiologie',
      'Analyses',
      'Identification',
    ],
    this.hoursWeekdays = '08:30 – 19:00',
    this.hoursSaturday = '09:00 – 13:00',
    this.phone = '',
  });

  String get initials =>
      name.replaceFirst('Dr. ', '').split(' ').map((e) => e[0]).take(2).join();

  static List<String> _parseServices(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [
      'Consultation',
      'Vaccination',
      'Chirurgie',
      'Radiologie',
      'Analyses',
      'Identification',
    ];
  }

  factory Vet.fromApi(Map<String, dynamic> json) => Vet(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        specialty: json['specialty']?.toString() ?? '',
        clinic: json['clinic']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviews: (json['reviews'] as num?)?.toInt() ?? 0,
        distance: json['distance']?.toString() ?? '',
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        availableToday: json['availableToday'] == true,
        color: Color((json['colorHex'] as num?)?.toInt() ?? 0xff4c7cf6),
        price: json['price']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        services: _parseServices(json['services']),
        hoursWeekdays: json['hoursWeekdays']?.toString() ?? '08:30 – 19:00',
        hoursSaturday: json['hoursSaturday']?.toString() ?? '09:00 – 13:00',
        phone: json['phone']?.toString() ?? '',
      );

  factory Vet.fromFirestore(String id, Map<String, dynamic> json) => Vet(
        id: id,
        name: json['name']?.toString() ?? '',
        specialty: json['specialty']?.toString() ?? '',
        clinic: json['clinic']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviews: (json['reviews'] as num?)?.toInt() ?? 0,
        distance: json['distance']?.toString() ?? '',
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        availableToday: json['availableToday'] == true,
        color: Color((json['colorHex'] as num?)?.toInt() ?? 0xff4c7cf6),
        price: json['price']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        services: _parseServices(json['services']),
        hoursWeekdays: json['hoursWeekdays']?.toString() ?? '08:30 – 19:00',
        hoursSaturday: json['hoursSaturday']?.toString() ?? '09:00 – 13:00',
        phone: json['phone']?.toString() ?? '',
      );

  Map<String, Object?> toFirestoreMap() => {
        'name': name,
        'specialty': specialty,
        'clinic': clinic,
        'address': address,
        'rating': rating,
        'reviews': reviews,
        'distance': distance,
        'experience': experience,
        'availableToday': availableToday,
        'colorHex': color.toARGB32(),
        'price': price,
        'image': image,
        'services': services,
        'hoursWeekdays': hoursWeekdays,
        'hoursSaturday': hoursSaturday,
        'phone': phone,
      };

  Map<String, Object?> toCacheMap() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'clinic': clinic,
        'address': address,
        'rating': rating,
        'reviews': reviews,
        'distance': distance,
        'experience': experience,
        'available_today': availableToday ? 1 : 0,
        'color_hex': color.toARGB32(),
        'price': price,
        'image': image,
        'services': services.join('|'),
        'hours_weekdays': hoursWeekdays,
        'hours_saturday': hoursSaturday,
        'phone': phone,
      };

  factory Vet.fromCacheMap(Map<String, Object?> m) => Vet(
        id: m['id'] as String,
        name: m['name'] as String,
        specialty: m['specialty'] as String,
        clinic: m['clinic'] as String,
        address: m['address'] as String,
        rating: (m['rating'] as num).toDouble(),
        reviews: m['reviews'] as int,
        distance: m['distance'] as String,
        experience: m['experience'] as int,
        availableToday: (m['available_today'] as int) == 1,
        color: Color(m['color_hex'] as int),
        price: m['price'] as String,
        image: (m['image'] as String?) ?? '',
        services: _parseServices(m['services']),
        hoursWeekdays: (m['hours_weekdays'] as String?) ?? '08:30 – 19:00',
        hoursSaturday: (m['hours_saturday'] as String?) ?? '09:00 – 13:00',
        phone: (m['phone'] as String?) ?? '',
      );
}

enum AppointmentStatus { upcoming, done, cancelled }

class Appointment {
  final int? id;
  final String vetId;
  final int petId;
  final String date;
  final String day;
  final String month;
  final String time;
  final String reason;
  final AppointmentStatus status;
  final Vet? vet;
  final Pet? pet;

  const Appointment({
    this.id,
    required this.vetId,
    required this.petId,
    required this.date,
    required this.day,
    required this.month,
    required this.time,
    required this.reason,
    required this.status,
    this.vet,
    this.pet,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'vet_id': vetId,
        'pet_id': petId,
        'date': date,
        'day': day,
        'month': month,
        'time': time,
        'reason': reason,
        'status': status.name,
      };

  factory Appointment.fromMap(Map<String, Object?> m) => Appointment(
        id: m['id'] as int?,
        vetId: m['vet_id'] as String,
        petId: m['pet_id'] as int,
        date: m['date'] as String,
        day: m['day'] as String,
        month: m['month'] as String,
        time: m['time'] as String,
        reason: m['reason'] as String,
        status: AppointmentStatus.values.byName(m['status'] as String),
      );

  Appointment copyWith({
    AppointmentStatus? status,
    Vet? vet,
    Pet? pet,
  }) =>
      Appointment(
        id: id,
        vetId: vetId,
        petId: petId,
        date: date,
        day: day,
        month: month,
        time: time,
        reason: reason,
        status: status ?? this.status,
        vet: vet ?? this.vet,
        pet: pet ?? this.pet,
      );
}

class Meal {
  final int? id;
  final int petId;
  final String name;
  final String time;
  final String food;
  final String quantity;
  final int calories;
  final bool done;
  final IconData icon;

  Meal({
    this.id,
    required this.petId,
    required this.name,
    required this.time,
    required this.food,
    required this.quantity,
    required this.calories,
    required this.done,
    required this.icon,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'time': time,
        'food': food,
        'quantity': quantity,
        'calories': calories,
        'done': done ? 1 : 0,
        'icon_code': icon.codePoint,
      };

  factory Meal.fromMap(Map<String, Object?> m) => Meal(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        name: m['name'] as String,
        time: m['time'] as String,
        food: m['food'] as String,
        quantity: m['quantity'] as String,
        calories: m['calories'] as int,
        done: (m['done'] as int) == 1,
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
      );

  Meal copyWith({bool? done}) => Meal(
        id: id,
        petId: petId,
        name: name,
        time: time,
        food: food,
        quantity: quantity,
        calories: calories,
        done: done ?? this.done,
        icon: icon,
      );
}

class FoodItem {
  final int? id;
  final int petId;
  final String name;
  final String emoji;
  final String note;
  final bool allowed;

  const FoodItem({
    this.id,
    required this.petId,
    required this.name,
    required this.emoji,
    required this.note,
    required this.allowed,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'emoji': emoji,
        'note': note,
        'allowed': allowed ? 1 : 0,
      };

  factory FoodItem.fromMap(Map<String, Object?> m) => FoodItem(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        name: m['name'] as String,
        emoji: m['emoji'] as String,
        note: m['note'] as String,
        allowed: (m['allowed'] as int) == 1,
      );
}

class Diet {
  final int? id;
  final int petId;
  final String dietType;
  final String goal;
  final int mealsPerDay;
  final String notes;

  const Diet({
    this.id,
    required this.petId,
    required this.dietType,
    required this.goal,
    required this.mealsPerDay,
    required this.notes,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'diet_type': dietType,
        'goal': goal,
        'meals_per_day': mealsPerDay,
        'notes': notes,
      };

  factory Diet.fromMap(Map<String, Object?> m) => Diet(
        id: m['id'] as int?,
        petId: m['pet_id'] as int,
        dietType: m['diet_type'] as String,
        goal: m['goal'] as String,
        mealsPerDay: m['meals_per_day'] as int,
        notes: m['notes'] as String? ?? '',
      );
}

enum NotificationType { vaccine, treatment, appointment, meal, custom }

class AppNotification {
  final int? id;
  final int? petId;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool unread;

  const AppNotification({
    this.id,
    this.petId,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.unread,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'title': title,
        'message': message,
        'time_label': time,
        'type': type.name,
        'unread': unread ? 1 : 0,
      };

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
        id: m['id'] as int?,
        petId: m['pet_id'] as int?,
        title: m['title'] as String,
        message: m['message'] as String,
        time: m['time_label'] as String,
        type: NotificationType.values.byName(m['type'] as String),
        unread: (m['unread'] as int) == 1,
      );
}

class CustomReminder {
  final int? id;
  final int? petId;
  final String title;
  final String category;
  final String date;
  final String time;
  final String repeat;
  final String note;

  const CustomReminder({
    this.id,
    this.petId,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.repeat,
    required this.note,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'title': title,
        'category': category,
        'date': date,
        'time': time,
        'repeat_mode': repeat,
        'note': note,
      };

  factory CustomReminder.fromMap(Map<String, Object?> m) => CustomReminder(
        id: m['id'] as int?,
        petId: m['pet_id'] as int?,
        title: m['title'] as String,
        category: m['category'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
        repeat: m['repeat_mode'] as String,
        note: m['note'] as String? ?? '',
      );
}

extension NotificationTypeStyle on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.vaccine => Icons.vaccines_rounded,
        NotificationType.treatment => Icons.medication_rounded,
        NotificationType.appointment => Icons.event_available_rounded,
        NotificationType.meal => Icons.restaurant_rounded,
        NotificationType.custom => Icons.star_rounded,
      };

  Color get color => switch (this) {
        NotificationType.vaccine => AppColors.health,
        NotificationType.treatment => AppColors.purple,
        NotificationType.appointment => AppColors.vet,
        NotificationType.meal => AppColors.food,
        NotificationType.custom => AppColors.reminder,
      };

  String get label => switch (this) {
        NotificationType.vaccine => 'Vaccination',
        NotificationType.treatment => 'Traitement',
        NotificationType.appointment => 'Rendez-vous',
        NotificationType.meal => 'Repas',
        NotificationType.custom => 'Personnalisé',
      };
}
