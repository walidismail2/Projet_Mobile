import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/alimentation/data/toxic_foods.dart';

/// Verdict, du plus grave au plus rassurant (ordre de tri).
enum SafetyLevel {
  toxic('Toxique', '☠️'),
  vetForbidden('Interdit par le véto', '⛔'),
  caution('À éviter', '⚠️'),
  vetAllowed('Autorisé par le véto', '✅'),
  safe('Sans danger', '✅');

  final String label;
  final String icon;
  const SafetyLevel(this.label, this.icon);

  bool get isWarning => index <= SafetyLevel.caution.index;
}

class SafetyResult {
  final SafetyLevel level;
  final String title;
  final String emoji;
  final String reason;

  /// « Votre vétérinaire » ou « Base PetCare ».
  final String source;

  const SafetyResult({
    required this.level,
    required this.title,
    required this.emoji,
    required this.reason,
    required this.source,
  });
}

/// « Peut-il manger ça ? » : croise la prescription du véto (aliments
/// autorisés / interdits de l'animal) et la base locale [foodFacts].
class FoodSafetyService {
  const FoodSafetyService._();

  /// Recherche libre (écran « Peut-il manger ça ? »).
  /// Correspond si un nom commence par la saisie, ou si un nom apparaît
  /// comme mot entier dans la saisie (« fromage blanc » → fromage).
  static List<SafetyResult> lookup(
    String query, {
    required String species,
    List<FoodItem> vetItems = const [],
  }) {
    final q = normalizeText(query);
    if (q.length < 2) return const [];
    bool matches(String name) {
      final n = normalizeText(name);
      return n.split(' ').any((w) => w.startsWith(q)) ||
          n.startsWith(q) ||
          _containsWord(q, n);
    }

    final results = <SafetyResult>[
      for (final item in vetItems)
        if (matches(item.name)) _fromVet(item),
      for (final fact in foodFacts)
        if (fact.names.any(matches)) _fromFact(fact, species),
    ];
    results.sort((a, b) => a.level.index.compareTo(b.level.index));
    return results;
  }

  /// Analyse un texte (nom d'aliment d'un repas, liste d'ingrédients d'un
  /// produit) : renvoie seulement les alertes, mots entiers uniquement.
  /// `includeCaution: false` pour les ingrédients (évite « sel », « lait »
  /// présents dans beaucoup de croquettes).
  static List<SafetyResult> checkText(
    String text, {
    required String species,
    List<FoodItem> vetItems = const [],
    bool includeCaution = true,
  }) {
    final t = normalizeText(text);
    if (t.isEmpty) return const [];
    final results = <SafetyResult>[
      for (final item in vetItems)
        if (!item.allowed && _containsWord(t, normalizeText(item.name)))
          _fromVet(item),
      for (final fact in foodFacts)
        if (fact.names.any((n) => _containsWord(t, n)))
          _fromFact(fact, species),
    ];
    return results
        .where(
          (r) =>
              r.level == SafetyLevel.toxic ||
              r.level == SafetyLevel.vetForbidden ||
              (includeCaution && r.level == SafetyLevel.caution),
        )
        .toList()
      ..sort((a, b) => a.level.index.compareTo(b.level.index));
  }

  /// `word` (éventuellement au pluriel en -s / -x) présent comme mot entier.
  static bool _containsWord(String text, String word) {
    if (word.isEmpty) return false;
    final re = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(word)}(s|x)?(\$|[^a-z0-9])',
    );
    return re.hasMatch(text);
  }

  static SafetyResult _fromVet(FoodItem item) => SafetyResult(
    level: item.allowed ? SafetyLevel.vetAllowed : SafetyLevel.vetForbidden,
    title: item.name,
    emoji: item.emoji,
    reason: item.note.isEmpty
        ? (item.allowed
              ? 'Fait partie du régime prescrit.'
              : 'Exclu du régime prescrit.')
        : item.note,
    source: 'Votre vétérinaire',
  );

  static SafetyResult _fromFact(FoodFact fact, String species) {
    final level = switch (fact.riskFor(species)) {
      FoodRisk.toxic => SafetyLevel.toxic,
      FoodRisk.caution => SafetyLevel.caution,
      FoodRisk.safe => SafetyLevel.safe,
    };
    return SafetyResult(
      level: level,
      title: fact.title,
      emoji: fact.emoji,
      reason: fact.reason,
      source: 'Base PetCare (ASPCA, Pet Poison Helpline)',
    );
  }
}
