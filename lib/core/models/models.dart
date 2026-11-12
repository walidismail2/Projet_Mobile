import 'package:flutter/material.dart';

import 'package:flutter_example/core/theme/app_theme.dart';

enum UserRole { owner, vet, admin }

UserRole userRoleFromString(String? raw) => switch (raw) {
      'vet' => UserRole.vet,
      'admin' => UserRole.admin,
      _ => UserRole.owner,
    };

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? photoPath;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.owner,
    this.address = '',
    this.latitude,
    this.longitude,
    this.photoPath,
  });

  bool get isVet => role == UserRole.vet;
  bool get isAdmin => role == UserRole.admin;
  bool get isOwner => role == UserRole.owner;
  bool get hasCoordinates => latitude != null && longitude != null;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  String get roleLabel => switch (role) {
        UserRole.admin => 'Administrateur',
        UserRole.vet => 'Vétérinaire',
        UserRole.owner => 'Propriétaire',
      };

  factory AppUser.fromApi(Map<String, dynamic> json) => AppUser(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: (json['username'] ?? json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        role: userRoleFromString(json['role']?.toString()),
        address: (json['address'] ?? '').toString(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photoPath: json['photo_path']?.toString() ?? json['photoPath']?.toString(),
      );

  Map<String, Object?> toPrefsMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'address': address,
        'latitude': latitude?.toString() ?? '',
        'longitude': longitude?.toString() ?? '',
        'photo_path': photoPath ?? '',
      };

  factory AppUser.fromPrefsMap(Map<String, String> m) => AppUser(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: userRoleFromString(m['role']),
        address: m['address'] ?? '',
        latitude: double.tryParse(m['latitude'] ?? ''),
        longitude: double.tryParse(m['longitude'] ?? ''),
        photoPath: (m['photo_path'] ?? '').isEmpty ? null : m['photo_path'],
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'photo_path': photoPath,
      };

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String,
        phone: (m['phone'] as String?) ?? '',
        role: userRoleFromString(m['role'] as String?),
        address: (m['address'] as String?) ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        photoPath: m['photo_path'] as String?,
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? address,
    double? latitude,
    double? longitude,
    String? photoPath,
    bool clearCoordinates = false,
    bool clearPhoto = false,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        address: address ?? this.address,
        latitude: clearCoordinates ? null : (latitude ?? this.latitude),
        longitude: clearCoordinates ? null : (longitude ?? this.longitude),
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      );
}

class NearestVetSuggestion {
  final Vet vet;
  final double distanceKm;

  const NearestVetSuggestion({
    required this.vet,
    required this.distanceKm,
  });

  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

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

  Vaccine copyWith({
    String? name,
    String? date,
    String? nextDate,
    String? vet,
  }) =>
      Vaccine(
        id: id,
        petId: petId,
        name: name ?? this.name,
        date: date ?? this.date,
        nextDate: nextDate ?? this.nextDate,
        vet: vet ?? this.vet,
        status: healthStatusFromNextDate(nextDate ?? this.nextDate),
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

  Treatment copyWith({
    String? name,
    String? dosage,
    String? frequency,
    int? currentDay,
    int? totalDays,
  }) =>
      Treatment(
        id: id,
        petId: petId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        currentDay: currentDay ?? this.currentDay,
        totalDays: totalDays ?? this.totalDays,
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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  Vet copyWith({
    String? name,
    String? specialty,
    String? clinic,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
  }) =>
      Vet(
        id: id,
        name: name ?? this.name,
        specialty: specialty ?? this.specialty,
        clinic: clinic ?? this.clinic,
        address: address ?? this.address,
        rating: rating,
        reviews: reviews,
        distance: distance,
        experience: experience,
        availableToday: availableToday,
        color: color,
        price: price,
        image: image,
        services: services,
        hoursWeekdays: hoursWeekdays,
        hoursSaturday: hoursSaturday,
        phone: phone ?? this.phone,
        latitude: clearCoordinates ? null : (latitude ?? this.latitude),
        longitude: clearCoordinates ? null : (longitude ?? this.longitude),
      );

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
        'latitude': latitude,
        'longitude': longitude,
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
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
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
    String? date,
    String? day,
    String? month,
    String? time,
    String? reason,
    AppointmentStatus? status,
    Vet? vet,
    Pet? pet,
  }) =>
      Appointment(
        id: id,
        vetId: vetId,
        petId: petId,
        date: date ?? this.date,
        day: day ?? this.day,
        month: month ?? this.month,
        time: time ?? this.time,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        vet: vet ?? this.vet,
        pet: pet ?? this.pet,
      );
}

/// Icônes de repas connues, retrouvées depuis `icon_code` (SQLite).
final _mealIcons = {
  for (final icon in const [
    Icons.restaurant_rounded,
    Icons.breakfast_dining_rounded,
    Icons.lunch_dining_rounded,
    Icons.dinner_dining_rounded,
    Icons.cookie_rounded,
  ])
    icon.codePoint: icon,
};

/// Repas planifié d'un animal.
///
/// - `date == null` → repas **quotidien**, valable à partir de `createdOn`.
/// - `date != null` → repas **ponctuel**, uniquement ce jour-là.
///
/// « Fait » n'est plus stocké ici : il dépend du jour → voir [MealLog].
class Meal {
  final int? id;
  final int petId;
  final String name;
  final String time;
  final String food;
  final String quantity;
  final int calories;
  final IconData icon;
  final DateTime? date;
  final DateTime createdOn;

  /// Produit Open Pet Food Facts lié (code-barres), si choisi.
  final String? productCode;
  final double? kcalPer100g;

  Meal({
    this.id,
    required this.petId,
    required this.name,
    required this.time,
    required this.food,
    required this.quantity,
    required this.calories,
    required this.icon,
    this.date,
    DateTime? createdOn,
    this.productCode,
    this.kcalPer100g,
  }) : createdOn = dayOnly(createdOn ?? DateTime.now());

  bool get isDaily => date == null;

  /// Le repas est-il prévu ce jour-là ?
  bool appliesOn(DateTime day) {
    final d = dayOnly(day);
    return date == null ? !d.isBefore(createdOn) : dayOnly(date!) == d;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'pet_id': petId,
        'name': name,
        'time': time,
        'food': food,
        'quantity': quantity,
        'calories': calories,
        // Colonne historique (v1–v11), remplacée par `meal_logs`.
        'done': 0,
        'icon_code': icon.codePoint,
        'date': date == null ? null : isoDate(date!),
        'created_on': isoDate(createdOn),
        'product_code': productCode,
        'kcal_100g': kcalPer100g,
      };

  factory Meal.fromMap(Map<String, Object?> m) {
    final date = m['date'] as String?;
    final created = m['created_on'] as String?;
    return Meal(
      id: m['id'] as int?,
      petId: m['pet_id'] as int,
      name: m['name'] as String,
      time: m['time'] as String,
      food: m['food'] as String,
      quantity: m['quantity'] as String,
      calories: m['calories'] as int,
      // Icône constante (un IconData construit à l'exécution casse le
      // « tree shaking » des icônes en build release).
      icon: _mealIcons[m['icon_code']] ?? Icons.restaurant_rounded,
      date: (date == null || date.isEmpty) ? null : DateTime.parse(date),
      createdOn: (created == null || created.isEmpty)
          ? DateTime(2000)
          : DateTime.parse(created),
      productCode: m['product_code'] as String?,
      kcalPer100g: (m['kcal_100g'] as num?)?.toDouble(),
    );
  }
}

/// Repas marqué « fait » un jour donné (copie figée pour l'historique,
/// même si le repas est modifié ou supprimé ensuite).
class MealLog {
  final int? id;
  final int? mealId;
  final int petId;
  final DateTime date;
  final String mealName;
  final String time;
  final String food;
  final String quantity;
  final int calories;

  const MealLog({
    this.id,
    this.mealId,
    required this.petId,
    required this.date,
    required this.mealName,
    required this.time,
    required this.food,
    required this.quantity,
    required this.calories,
  });

  factory MealLog.fromMeal(Meal meal, DateTime day) => MealLog(
        mealId: meal.id,
        petId: meal.petId,
        date: dayOnly(day),
        mealName: meal.name,
        time: meal.time,
        food: meal.food,
        quantity: meal.quantity,
        calories: meal.calories,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'meal_id': mealId,
        'pet_id': petId,
        'date': isoDate(date),
        'meal_name': mealName,
        'time': time,
        'food': food,
        'quantity': quantity,
        'calories': calories,
      };

  factory MealLog.fromMap(Map<String, Object?> m) => MealLog(
        id: m['id'] as int?,
        mealId: m['meal_id'] as int?,
        petId: m['pet_id'] as int,
        date: DateTime.parse(m['date'] as String),
        mealName: m['meal_name'] as String,
        time: m['time'] as String,
        food: m['food'] as String,
        quantity: m['quantity'] as String,
        calories: m['calories'] as int,
      );
}

/// Ligne affichée pour un jour : repas prévu (+ log s'il est fait), ou log
/// seul quand le repas a été supprimé depuis.
class MealEntry {
  final Meal? meal;
  final MealLog? log;

  const MealEntry({this.meal, this.log})
      : assert(meal != null || log != null);

  bool get done => log != null;
  String get name => log?.mealName ?? meal!.name;
  String get time => log?.time ?? meal!.time;
  String get food => log?.food ?? meal!.food;
  String get quantity => log?.quantity ?? meal!.quantity;
  int get calories => log?.calories ?? meal!.calories;
}

/// Produit d'Open Pet Food Facts (mis en cache dans `pet_food_cache`).
class PetFoodProduct {
  final String code;
  final String name;
  final String brand;
  final String imageUrl;
  final String quantity;

  /// `dog`, `cat` ou `''` (les deux / inconnu).
  final String species;
  final double? kcalPer100g;

  /// `true` si les kcal sont estimées depuis l'analyse (protéines, graisses…).
  final bool kcalEstimated;
  final String ingredients;

  const PetFoodProduct({
    required this.code,
    required this.name,
    required this.brand,
    this.imageUrl = '',
    this.quantity = '',
    this.species = '',
    this.kcalPer100g,
    this.kcalEstimated = false,
    this.ingredients = '',
  });

  String get displayName => brand.isEmpty ? name : '$brand · $name';

  Map<String, Object?> toMap() => {
        'code': code,
        'name': name,
        'brand': brand,
        'image_url': imageUrl,
        'quantity': quantity,
        'species': species,
        'kcal_100g': kcalPer100g,
        'kcal_estimated': kcalEstimated ? 1 : 0,
        'ingredients': ingredients,
        'search_text': normalizeText('$brand $name'),
        'fetched_at': DateTime.now().toIso8601String(),
      };

  factory PetFoodProduct.fromMap(Map<String, Object?> m) => PetFoodProduct(
        code: m['code'] as String,
        name: m['name'] as String,
        brand: m['brand'] as String? ?? '',
        imageUrl: m['image_url'] as String? ?? '',
        quantity: m['quantity'] as String? ?? '',
        species: m['species'] as String? ?? '',
        kcalPer100g: (m['kcal_100g'] as num?)?.toDouble(),
        kcalEstimated: (m['kcal_estimated'] as int? ?? 0) == 1,
        ingredients: m['ingredients'] as String? ?? '',
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

/// Pesée d'un animal (module Alimentation · suivi du poids).
/// `date` est stockée en ISO `AAAA-MM-JJ` pour trier en SQL.
class WeightLog {
  final int? id;
  final int petId;
  final double weight;
  final DateTime date;
  final String note;

  const WeightLog({
    this.id,
    required this.petId,
    required this.weight,
    required this.date,
    this.note = '',
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'pet_id': petId,
    'weight': weight,
    'date': isoDate(date),
    'note': note,
  };

  factory WeightLog.fromMap(Map<String, Object?> m) => WeightLog(
    id: m['id'] as int?,
    petId: m['pet_id'] as int,
    weight: (m['weight'] as num).toDouble(),
    date: DateTime.parse(m['date'] as String),
    note: m['note'] as String? ?? '',
  );
}

/// Sac / stock de nourriture d'un animal (module Alimentation).
///
/// Le reste est estimé : `bagGrams - jours écoulés × dailyGrams`
/// depuis `openedDate` (ouverture du sac).
class FoodStock {
  final int? id;
  final int petId;
  final String name;
  final int bagGrams;
  final int dailyGrams;
  final DateTime openedDate;
  final int alertDays;

  const FoodStock({
    this.id,
    required this.petId,
    required this.name,
    required this.bagGrams,
    required this.dailyGrams,
    required this.openedDate,
    this.alertDays = 3,
  });

  /// Nombre total de jours couverts par le sac.
  double get totalDays => dailyGrams <= 0 ? 0 : bagGrams / dailyGrams;

  /// Date à laquelle le sac sera vide.
  DateTime get runOutDate {
    final d = DateTime(openedDate.year, openedDate.month, openedDate.day);
    return d.add(Duration(days: totalDays.floor()));
  }

  int remainingGrams([DateTime? now]) {
    if (dailyGrams <= 0) return bagGrams;
    final today = _day(now ?? DateTime.now());
    final days = today.difference(_day(openedDate)).inDays;
    final elapsed = days < 0 ? 0 : days;
    final left = bagGrams - elapsed * dailyGrams;
    return left.clamp(0, bagGrams);
  }

  int daysLeft([DateTime? now]) =>
      dailyGrams <= 0 ? 0 : remainingGrams(now) ~/ dailyGrams;

  /// Part restante entre 0 et 1 (barre de progression).
  double remainingRatio([DateTime? now]) =>
      bagGrams <= 0 ? 0 : remainingGrams(now) / bagGrams;

  bool isLow([DateTime? now]) => daysLeft(now) <= alertDays;

  /// Jour (à 9h) où l'alerte « stock bas » doit partir.
  DateTime get alertDate {
    final d = runOutDate.subtract(Duration(days: alertDays));
    return DateTime(d.year, d.month, d.day, 9);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, Object?> toMap() => {
    'id': id,
    'pet_id': petId,
    'name': name,
    'bag_grams': bagGrams,
    'daily_grams': dailyGrams,
    'opened_date': isoDate(openedDate),
    'alert_days': alertDays,
  };

  factory FoodStock.fromMap(Map<String, Object?> m) => FoodStock(
    id: m['id'] as int?,
    petId: m['pet_id'] as int,
    name: m['name'] as String,
    bagGrams: m['bag_grams'] as int,
    dailyGrams: m['daily_grams'] as int,
    openedDate: DateTime.parse(m['opened_date'] as String),
    alertDays: m['alert_days'] as int? ?? 3,
  );

  FoodStock copyWith({
    int? id,
    String? name,
    int? bagGrams,
    int? dailyGrams,
    DateTime? openedDate,
    int? alertDays,
  }) => FoodStock(
    id: id ?? this.id,
    petId: petId,
    name: name ?? this.name,
    bagGrams: bagGrams ?? this.bagGrams,
    dailyGrams: dailyGrams ?? this.dailyGrams,
    openedDate: openedDate ?? this.openedDate,
    alertDays: alertDays ?? this.alertDays,
  );
}

/// Date sans l'heure.
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Minuscules, sans accents ni ligatures — pour comparer des textes saisis.
String normalizeText(String raw) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buf = StringBuffer();
  for (final ch in raw.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    if (i >= 0) {
      buf.write(to[i]);
    } else if (ch == 'œ') {
      buf.write('oe');
    } else if (ch == 'æ') {
      buf.write('ae');
    } else if (ch == '’') {
      buf.write("'");
    } else {
      buf.write(ch);
    }
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// `AAAA-MM-JJ` (tri SQL).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// « 12,5 » / « 12.5 » → 12.5
double? parseDecimal(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

/// Convertit une quantité libre (« 100 g », « 0,5 kg », « 1.2kg ») en grammes.
/// Renvoie null si aucune masse n'est reconnue (ex. « 1 boîte »).
int? parseGrams(String raw) {
  final m = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(kg|g)\b',
    caseSensitive: false,
  ).firstMatch(raw);
  if (m == null) return null;
  final value = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  if (value == null) return null;
  final grams = m.group(2)!.toLowerCase() == 'kg' ? value * 1000 : value;
  return grams.round();
}

enum NotificationType {
  vaccine,
  treatment,
  appointment,
  meal,
  birthday,
  custom,
}

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

class Accessory {
  final int? id;
  final String name;
  final String category;
  final String species; // Tous / Chien / Chat / Lapin
  final double price;
  final String description;
  final String emoji;
  final int stock;

  const Accessory({
    this.id,
    required this.name,
    required this.category,
    this.species = 'Tous',
    required this.price,
    this.description = '',
    this.emoji = '🛍️',
    this.stock = 10,
  });

  String get priceLabel =>
      '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} DT';

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'species': species,
        'price': price,
        'description': description,
        'emoji': emoji,
        'stock': stock,
      };

  factory Accessory.fromMap(Map<String, Object?> m) => Accessory(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        species: (m['species'] as String?) ?? 'Tous',
        price: (m['price'] as num).toDouble(),
        description: (m['description'] as String?) ?? '',
        emoji: (m['emoji'] as String?) ?? '🛍️',
        stock: (m['stock'] as int?) ?? 0,
      );

  Accessory copyWith({
    String? name,
    String? category,
    String? species,
    double? price,
    String? description,
    String? emoji,
    int? stock,
  }) =>
      Accessory(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        species: species ?? this.species,
        price: price ?? this.price,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        stock: stock ?? this.stock,
      );
}

class CartItem {
  final int? id;
  final String ownerId;
  final int accessoryId;
  final int quantity;
  final Accessory? accessory;

  const CartItem({
    this.id,
    required this.ownerId,
    required this.accessoryId,
    this.quantity = 1,
    this.accessory,
  });

  double get lineTotal => (accessory?.price ?? 0) * quantity;

  Map<String, Object?> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'accessory_id': accessoryId,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, Object?> m, {Accessory? accessory}) =>
      CartItem(
        id: m['id'] as int?,
        ownerId: m['owner_id'] as String,
        accessoryId: m['accessory_id'] as int,
        quantity: (m['quantity'] as int?) ?? 1,
        accessory: accessory,
      );

  CartItem copyWith({int? quantity, Accessory? accessory}) => CartItem(
        id: id,
        ownerId: ownerId,
        accessoryId: accessoryId,
        quantity: quantity ?? this.quantity,
        accessory: accessory ?? this.accessory,
      );
}

extension NotificationTypeStyle on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.vaccine => Icons.vaccines_rounded,
        NotificationType.treatment => Icons.medication_rounded,
        NotificationType.appointment => Icons.event_available_rounded,
        NotificationType.meal => Icons.restaurant_rounded,
        NotificationType.birthday => Icons.cake_rounded,
        NotificationType.custom => Icons.star_rounded,
      };

  Color get color => switch (this) {
        NotificationType.vaccine => AppColors.health,
        NotificationType.treatment => AppColors.purple,
        NotificationType.appointment => AppColors.vet,
        NotificationType.meal => AppColors.food,
        NotificationType.birthday => const Color(0xFFEC4899),
        NotificationType.custom => AppColors.reminder,
      };

  String get label => switch (this) {
        NotificationType.vaccine => 'Vaccination',
        NotificationType.treatment => 'Traitement',
        NotificationType.appointment => 'Rendez-vous',
        NotificationType.meal => 'Repas',
        NotificationType.birthday => 'Anniversaire',
        NotificationType.custom => 'Personnalisé',
      };
}
