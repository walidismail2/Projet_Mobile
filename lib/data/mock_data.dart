import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Pet {
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

  const Pet({
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
  });
}

enum HealthStatus { upToDate, soon, late }

class Vaccine {
  final String name;
  final String date;
  final String nextDate;
  final String vet;
  final HealthStatus status;

  const Vaccine(this.name, this.date, this.nextDate, this.vet, this.status);
}

class Treatment {
  final String name;
  final String dosage;
  final String frequency;
  final int currentDay;
  final int totalDays;
  final IconData icon;

  const Treatment(this.name, this.dosage, this.frequency, this.currentDay,
      this.totalDays, this.icon);
}

class MedicalEvent {
  final String title;
  final String date;
  final String description;
  final IconData icon;
  final Color color;

  const MedicalEvent(
      this.title, this.date, this.description, this.icon, this.color);
}

class MedicalDocument {
  final String name;
  final String date;
  final String size;
  final bool isPdf;

  const MedicalDocument(this.name, this.date, this.size, this.isPdf);
}

class Vet {
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

  const Vet({
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
  });

  String get initials =>
      name.replaceFirst('Dr. ', '').split(' ').map((e) => e[0]).take(2).join();
}

enum AppointmentStatus { upcoming, done, cancelled }

class Appointment {
  final Vet vet;
  final Pet pet;
  final String date;
  final String day;
  final String month;
  final String time;
  final String reason;
  final AppointmentStatus status;

  const Appointment({
    required this.vet,
    required this.pet,
    required this.date,
    required this.day,
    required this.month,
    required this.time,
    required this.reason,
    required this.status,
  });
}

class Meal {
  final String name;
  final String time;
  final String food;
  final String quantity;
  final int calories;
  final bool done;
  final IconData icon;

  const Meal(this.name, this.time, this.food, this.quantity, this.calories,
      this.done, this.icon);
}

class FoodItem {
  final String name;
  final String emoji;
  final String note;

  const FoodItem(this.name, this.emoji, this.note);
}

enum NotificationType { vaccine, treatment, appointment, meal, custom }

class AppNotification {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool unread;

  const AppNotification(
      this.title, this.message, this.time, this.type, this.unread);
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

class MockData {
  static const ownerName = 'Sarah Benali';
  static const ownerEmail = 'sarah.benali@email.com';
  static const ownerPhone = '+33 6 12 34 56 78';

  static const pets = [
    Pet(
      name: 'Rocky',
      species: 'Chien',
      breed: 'Golden Retriever',
      age: '3 ans',
      weight: 28.5,
      sex: 'Mâle',
      emoji: '🐶',
      color: Color(0xFFFFB74D),
      birthDate: '12/04/2023',
      chip: '250 26 9812 345 678',
      sterilized: true,
    ),
    Pet(
      name: 'Luna',
      species: 'Chat',
      breed: 'Européen',
      age: '2 ans',
      weight: 4.2,
      sex: 'Femelle',
      emoji: '🐱',
      color: Color(0xFF9FA8DA),
      birthDate: '03/08/2024',
      chip: '250 26 9812 111 222',
      sterilized: true,
    ),
    Pet(
      name: 'Coco',
      species: 'Lapin',
      breed: 'Bélier nain',
      age: '1 an',
      weight: 1.6,
      sex: 'Femelle',
      emoji: '🐰',
      color: Color(0xFFA5D6A7),
      birthDate: '20/01/2025',
      chip: '—',
      sterilized: false,
    ),
  ];

  static const vaccines = [
    Vaccine('Rage', '15/03/2026', '15/03/2027', 'Dr. Martin',
        HealthStatus.upToDate),
    Vaccine('CHPPi (Carré, Hépatite…)', '10/10/2025', '10/10/2026',
        'Dr. Martin', HealthStatus.soon),
    Vaccine('Leptospirose', '02/08/2025', '02/08/2026', 'Dr. Leroy',
        HealthStatus.late),
    Vaccine('Toux du chenil', '20/05/2026', '20/05/2027', 'Dr. Martin',
        HealthStatus.upToDate),
  ];

  static const treatments = [
    Treatment('Antibiotique Clavubactin', '1 comprimé · 250 mg',
        '2 fois par jour', 4, 10, Icons.medication_rounded),
    Treatment('Vermifuge Milbemax', '1 comprimé', 'Tous les 3 mois', 1, 1,
        Icons.bug_report_rounded),
    Treatment('Anti-puces Frontline', '1 pipette', '1 fois par mois', 3, 12,
        Icons.water_drop_rounded),
  ];

  static const medicalHistory = [
    MedicalEvent('Consultation de contrôle', '22 sept. 2026',
        'Bon état général. Poids stable.', Icons.monitor_heart_rounded,
        AppColors.vet),
    MedicalEvent('Otite traitée', '05 juil. 2026',
        'Oreille gauche — gouttes auriculaires 7 jours.', Icons.hearing_rounded,
        AppColors.purple),
    MedicalEvent('Vaccin Rage', '15 mars 2026', 'Rappel annuel effectué.',
        Icons.vaccines_rounded, AppColors.health),
    MedicalEvent('Détartrage', '18 nov. 2025', 'Sous anesthésie légère.',
        Icons.cleaning_services_rounded, AppColors.food),
    MedicalEvent('Stérilisation', '02 févr. 2025',
        'Intervention réussie, suivi OK.', Icons.healing_rounded,
        AppColors.reminder),
  ];

  static const documents = [
    MedicalDocument('Carnet de vaccination', '15/03/2026', '1,2 Mo', true),
    MedicalDocument('Radio hanche', '22/09/2026', '3,4 Mo', false),
    MedicalDocument('Analyse sanguine', '05/07/2026', '850 Ko', true),
    MedicalDocument('Ordonnance otite', '05/07/2026', '420 Ko', true),
  ];

  static const vets = [
    Vet(
      name: 'Dr. Claire Martin',
      specialty: 'Généraliste',
      clinic: 'Clinique VetCare',
      address: '12 rue des Lilas, 75011 Paris',
      rating: 4.9,
      reviews: 214,
      distance: '1,2 km',
      experience: 12,
      availableToday: true,
      color: AppColors.vet,
      price: '45 €',
    ),
    Vet(
      name: 'Dr. Thomas Leroy',
      specialty: 'Chirurgie',
      clinic: 'Centre Vétérinaire Bastille',
      address: '48 bd Voltaire, 75011 Paris',
      rating: 4.7,
      reviews: 158,
      distance: '2,5 km',
      experience: 15,
      availableToday: false,
      color: AppColors.purple,
      price: '60 €',
    ),
    Vet(
      name: 'Dr. Inès Haddad',
      specialty: 'NAC',
      clinic: 'Clinique des Petits Compagnons',
      address: '5 av. de la République, 75003 Paris',
      rating: 4.8,
      reviews: 97,
      distance: '3,1 km',
      experience: 8,
      availableToday: true,
      color: AppColors.health,
      price: '50 €',
    ),
    Vet(
      name: 'Dr. Paul Moreau',
      specialty: 'Dentaire',
      clinic: 'Dentivet Paris',
      address: '30 rue Oberkampf, 75011 Paris',
      rating: 4.6,
      reviews: 73,
      distance: '4,0 km',
      experience: 10,
      availableToday: false,
      color: AppColors.food,
      price: '55 €',
    ),
  ];

  static final appointments = [
    Appointment(
      vet: vets[0],
      pet: pets[0],
      date: 'Vendredi 2 octobre',
      day: '02',
      month: 'OCT',
      time: '10:30',
      reason: 'Vaccination CHPPi',
      status: AppointmentStatus.upcoming,
    ),
    Appointment(
      vet: vets[2],
      pet: pets[2],
      date: 'Mardi 13 octobre',
      day: '13',
      month: 'OCT',
      time: '15:00',
      reason: 'Contrôle dentaire',
      status: AppointmentStatus.upcoming,
    ),
    Appointment(
      vet: vets[0],
      pet: pets[0],
      date: 'Mardi 22 septembre',
      day: '22',
      month: 'SEPT',
      time: '09:00',
      reason: 'Consultation de contrôle',
      status: AppointmentStatus.done,
    ),
    Appointment(
      vet: vets[1],
      pet: pets[1],
      date: 'Lundi 7 septembre',
      day: '07',
      month: 'SEPT',
      time: '17:30',
      reason: 'Bilan annuel',
      status: AppointmentStatus.cancelled,
    ),
    Appointment(
      vet: vets[0],
      pet: pets[0],
      date: 'Dimanche 5 juillet',
      day: '05',
      month: 'JUIL',
      time: '11:00',
      reason: 'Otite',
      status: AppointmentStatus.done,
    ),
  ];

  static const meals = [
    Meal('Petit-déjeuner', '07:30', 'Croquettes Royal Canin', '120 g', 420,
        true, Icons.wb_sunny_rounded),
    Meal('Déjeuner', '12:30', 'Pâtée poulet & riz', '100 g', 180, true,
        Icons.lunch_dining_rounded),
    Meal('Friandise', '16:00', 'Bâtonnet dentaire', '1 unité', 70, false,
        Icons.cookie_rounded),
    Meal('Dîner', '19:30', 'Croquettes Royal Canin', '130 g', 450, false,
        Icons.nights_stay_rounded),
  ];

  static const allowedFoods = [
    FoodItem('Poulet cuit', '🍗', 'Sans os ni assaisonnement'),
    FoodItem('Riz blanc', '🍚', 'Digestion facile'),
    FoodItem('Carotte', '🥕', 'Crue ou cuite'),
    FoodItem('Pomme', '🍎', 'Sans pépins'),
    FoodItem('Potiron', '🎃', 'Riche en fibres'),
  ];

  static const forbiddenFoods = [
    FoodItem('Chocolat', '🍫', 'Toxique — théobromine'),
    FoodItem('Raisin', '🍇', 'Insuffisance rénale'),
    FoodItem('Oignon / ail', '🧅', 'Anémie'),
    FoodItem('Avocat', '🥑', 'Toxique — persine'),
    FoodItem('Os cuits', '🦴', 'Risque d\'éclats'),
  ];

  static const notifications = [
    AppNotification('Rendez-vous demain',
        'Rocky a rendez-vous avec Dr. Claire Martin demain à 10:30.',
        'Il y a 10 min', NotificationType.appointment, true),
    AppNotification('Heure du dîner 🍖',
        'C\'est l\'heure du dîner de Rocky : 130 g de croquettes.',
        'Il y a 1 h', NotificationType.meal, true),
    AppNotification('Traitement à donner',
        'Luna : 1 comprimé de Clavubactin (jour 4/10).', 'Il y a 3 h',
        NotificationType.treatment, false),
    AppNotification('Vaccin bientôt dû',
        'Le rappel CHPPi de Rocky est prévu le 10/10/2026.', 'Hier',
        NotificationType.vaccine, false),
    AppNotification('Brossage hebdomadaire',
        'N\'oubliez pas de brosser Luna aujourd\'hui ✨', 'Hier',
        NotificationType.custom, false),
    AppNotification('Vaccin en retard',
        'Le rappel Leptospirose de Rocky est en retard.', 'Lun.',
        NotificationType.vaccine, false),
  ];
}
