import 'package:flutter_example/core/models/models.dart';

/// Périodes proposées dans la recherche de l'historique des repas.
enum HistoryPeriod {
  last7('7 jours'),
  thisMonth('Ce mois'),
  lastMonth('Mois dernier'),
  last30('30 jours'),
  all('Tout'),
  custom('Dates…');

  final String label;
  const HistoryPeriod(this.label);

  /// Bornes incluses `(du, au)` ; `null` = pas de limite.
  /// [custom] renvoie `(null, null)` : les dates viennent du sélecteur.
  (DateTime?, DateTime?) range(DateTime now) {
    final today = dayOnly(now);
    return switch (this) {
      last7 => (today.subtract(const Duration(days: 6)), today),
      last30 => (today.subtract(const Duration(days: 29)), today),
      thisMonth => (DateTime(today.year, today.month), today),
      lastMonth => (
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month, 0),
      ),
      all || custom => (null, null),
    };
  }
}

/// Filtre texte : chaque mot saisi doit apparaître dans l'aliment ou le
/// type de repas (sans accents ni majuscules). « royal canin » trouve
/// « Royal Canin · Puppy Food ».
List<MealLog> filterLogsByText(List<MealLog> logs, String query) {
  final words = normalizeText(
    query,
  ).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return logs;
  return logs.where((l) {
    final hay = normalizeText('${l.food} ${l.mealName}');
    return words.every(hay.contains);
  }).toList();
}

/// Totaux affichés au-dessus des résultats.
class MealHistorySummary {
  final int meals;
  final int totalKcal;

  /// Jours distincts ayant au moins un repas dans les résultats.
  final int days;

  /// Somme des quantités exprimées en g / kg (les autres sont ignorées).
  final int grams;

  /// Repas dont la quantité n'est pas en g / kg (« 1 boîte »).
  final int mealsWithoutGrams;

  const MealHistorySummary({
    required this.meals,
    required this.totalKcal,
    required this.days,
    required this.grams,
    required this.mealsWithoutGrams,
  });

  int get kcalPerDay => days == 0 ? 0 : (totalKcal / days).round();

  factory MealHistorySummary.of(List<MealLog> logs) {
    var grams = 0;
    var withoutGrams = 0;
    for (final l in logs) {
      final g = parseGrams(l.quantity);
      if (g == null) {
        withoutGrams++;
      } else {
        grams += g;
      }
    }
    return MealHistorySummary(
      meals: logs.length,
      totalKcal: logs.fold(0, (s, l) => s + l.calories),
      days: logs.map((l) => l.date).toSet().length,
      grams: grams,
      mealsWithoutGrams: withoutGrams,
    );
  }
}

/// Regroupe par jour, du plus récent au plus ancien ; repas triés par heure.
List<(DateTime, List<MealLog>)> groupLogsByDay(List<MealLog> logs) {
  final byDay = <DateTime, List<MealLog>>{};
  for (final l in logs) {
    byDay.putIfAbsent(dayOnly(l.date), () => []).add(l);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days)
      (d, byDay[d]!..sort((a, b) => a.time.compareTo(b.time))),
  ];
}

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// « Aujourd'hui », « Hier », « Demain » ou « mer. 12 nov. ».
String frDayLabel(DateTime day, {bool long = false}) {
  final d = dayOnly(day);
  final today = dayOnly(DateTime.now());
  final diff = d.difference(today).inDays;
  final full =
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
      '${d.year != today.year ? ' ${d.year}' : ''}';
  final rel = switch (diff) {
    0 => "Aujourd'hui",
    -1 => 'Hier',
    1 => 'Demain',
    _ => null,
  };
  if (rel == null) return full;
  return long ? '$rel · $full' : rel;
}
