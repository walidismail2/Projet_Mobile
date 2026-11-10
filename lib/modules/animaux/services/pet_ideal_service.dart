import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_example/core/models/models.dart';

enum PetLifeStage { puppy, adult, senior }

extension PetLifeStageX on PetLifeStage {
  String label(String species) {
    if (species == 'Chat') {
      return switch (this) {
        PetLifeStage.puppy => 'Chaton',
        PetLifeStage.adult => 'Adulte',
        PetLifeStage.senior => 'Senior',
      };
    }
    if (species == 'Chien') {
      return switch (this) {
        PetLifeStage.puppy => 'Chiot',
        PetLifeStage.adult => 'Adulte',
        PetLifeStage.senior => 'Senior',
      };
    }
    return switch (this) {
      PetLifeStage.puppy => 'Jeune',
      PetLifeStage.adult => 'Adulte',
      PetLifeStage.senior => 'Senior',
    };
  }
}

class PetIdealProfile {
  final PetLifeStage stage;
  final String stageLabel;
  final double? weightMinKg;
  final double? weightMaxKg;
  final String? lifeSpanLabel;
  final int? exerciseMinutes;
  final List<String> tips;
  final String source;
  final String? sourceUrl;
  final bool fromApi;
  final String weightVerdict;
  final String summary;

  const PetIdealProfile({
    required this.stage,
    required this.stageLabel,
    required this.tips,
    required this.source,
    required this.fromApi,
    required this.weightVerdict,
    required this.summary,
    this.sourceUrl,
    this.weightMinKg,
    this.weightMaxKg,
    this.lifeSpanLabel,
    this.exerciseMinutes,
  });

  String? get weightRangeLabel {
    if (weightMinKg == null || weightMaxKg == null) return null;
    if (weightMinKg == weightMaxKg) {
      return '${weightMinKg!.toStringAsFixed(1)} kg';
    }
    return '${weightMinKg!.toStringAsFixed(1)} – ${weightMaxKg!.toStringAsFixed(1)} kg';
  }
}

/// Idéaux race + âge : Dog API / Cat API si possible, sinon règles locales.
class PetIdealService {
  final http.Client _client;
  static List<Map<String, dynamic>>? _dogBreedCache;
  static List<Map<String, dynamic>>? _catBreedCache;

  PetIdealService({http.Client? client}) : _client = client ?? http.Client();

  Future<PetIdealProfile> forPet(Pet pet) async {
    final stage = _lifeStage(pet);
    final stageLabel = stage.label(pet.species);

    BreedStats? stats;
    var source = 'Références locales';
    String? sourceUrl;
    var fromApi = false;

    try {
      if (pet.species == 'Chien') {
        stats = await _findDogBreed(pet.breed);
        if (stats != null) {
          source = 'dogapi.dog';
          sourceUrl = 'https://dogapi.dog/';
          fromApi = true;
        }
      } else if (pet.species == 'Chat') {
        stats = await _findCatBreed(pet.breed);
        if (stats != null) {
          source = 'thecatapi.com';
          sourceUrl = 'https://thecatapi.com/';
          fromApi = true;
        }
      }
    } catch (_) {
      stats = null;
    }

    stats ??= _localStats(pet.species, pet.breed);

    final weightAdj = _adjustWeightForAge(
      min: stats.weightMin,
      max: stats.weightMax,
      stage: stage,
      species: pet.species,
    );

    final tips = <String>[
      ..._stageTips(pet.species, stage),
      if (stats.exerciseMinutes != null && pet.species == 'Chien')
        stage == PetLifeStage.puppy
            ? 'Activité douce : vise ~${(stats.exerciseMinutes! * 0.6).round()} min/jour (croissance).'
            : stage == PetLifeStage.senior
                ? 'Activité adaptée : ~${(stats.exerciseMinutes! * 0.7).round()} min/jour, sans excès.'
                : 'Exercice idéal race : ~${stats.exerciseMinutes} min/jour.',
      if (stats.temperament.isNotEmpty)
        'Tempérament typique : ${stats.temperament.take(4).join(', ')}.',
      if (!pet.sterilized && stage != PetLifeStage.puppy)
        'Stérilisation : à discuter avec le véto selon âge et race.',
    ];

    final verdict = _weightVerdict(pet.weight, weightAdj.$1, weightAdj.$2);
    final summary = _summary(
      pet: pet,
      stageLabel: stageLabel,
      min: weightAdj.$1,
      max: weightAdj.$2,
      verdict: verdict,
    );

    return PetIdealProfile(
      stage: stage,
      stageLabel: stageLabel,
      weightMinKg: weightAdj.$1,
      weightMaxKg: weightAdj.$2,
      lifeSpanLabel: stats.lifeSpanLabel,
      exerciseMinutes: stats.exerciseMinutes,
      tips: tips,
      source: source,
      sourceUrl: sourceUrl,
      fromApi: fromApi,
      weightVerdict: verdict,
      summary: summary,
    );
  }

  PetLifeStage _lifeStage(Pet pet) {
    final months = _ageInMonths(pet.birthDate);
    if (pet.species == 'Chat') {
      if (months < 12) return PetLifeStage.puppy;
      if (months >= 10 * 12) return PetLifeStage.senior;
      return PetLifeStage.adult;
    }
    if (pet.species == 'Chien') {
      if (months < 12) return PetLifeStage.puppy;
      // grands chiens souvent seniors plus tôt
      final seniorYears = (pet.weight >= 25) ? 7 : 8;
      if (months >= seniorYears * 12) return PetLifeStage.senior;
      return PetLifeStage.adult;
    }
    if (months < 12) return PetLifeStage.puppy;
    if (months >= 8 * 12) return PetLifeStage.senior;
    return PetLifeStage.adult;
  }

  int _ageInMonths(String birthDate) {
    final birth = parseFrDate(birthDate);
    if (birth == null) return 24;
    final now = DateTime.now();
    var months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) months -= 1;
    return months.clamp(0, 400);
  }

  (double?, double?) _adjustWeightForAge({
    required double? min,
    required double? max,
    required PetLifeStage stage,
    required String species,
  }) {
    if (min == null || max == null) return (null, null);
    return switch (stage) {
      PetLifeStage.puppy => (min * 0.35, max * 0.75),
      PetLifeStage.senior => (min * 0.95, max * 1.05),
      PetLifeStage.adult => (min, max),
    };
  }

  String _weightVerdict(double weight, double? min, double? max) {
    if (min == null || max == null) {
      return 'Pas de fourchette précise : surveille l’évolution du poids.';
    }
    if (weight < min * 0.9) {
      return 'Sous le poids idéal → parle nutrition / vermifuge au véto.';
    }
    if (weight > max * 1.1) {
      return 'Au-dessus du poids idéal → ajuste rations et activité.';
    }
    if (weight < min) return 'Un peu léger, mais proche de la cible.';
    if (weight > max) return 'Un peu au-dessus, à surveiller.';
    return 'Poids dans la fourchette idéale 👍';
  }

  String _summary({
    required Pet pet,
    required String stageLabel,
    required double? min,
    required double? max,
    required String verdict,
  }) {
    final range = (min != null && max != null)
        ? 'Poids cible ≈ ${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} kg'
        : 'Poids cible : selon morphologie';
    return '${pet.name} est en phase « $stageLabel ». $range. Actuel : ${pet.weight} kg. $verdict';
  }

  List<String> _stageTips(String species, PetLifeStage stage) {
    if (species == 'Chien') {
      return switch (stage) {
        PetLifeStage.puppy => [
            'Croissance : 3–4 repas/jour, croquettes chiot adaptées à la taille.',
            'Vaccins de base + vermifuge selon calendrier véto.',
            'Socialisation douce avant ~4 mois.',
          ],
        PetLifeStage.adult => [
            '1–2 repas/jour, ration stable selon activité.',
            'Contrôle annuel + rappels vaccins / antiparasitaires.',
            'Brossage et contrôle dents / coussinets réguliers.',
          ],
        PetLifeStage.senior => [
            'Aliment senior : digeste, joints / reins selon avis véto.',
            'Bilan sanguin annuel (ou bi-annuel).',
            'Sorties plus courtes, couchage orthopédique utile.',
          ],
      };
    }
    if (species == 'Chat') {
      return switch (stage) {
        PetLifeStage.puppy => [
            'Chaton : plusieurs petits repas, croquettes croissance.',
            'Vaccins + identification / stérilisation à planifier.',
            'Jeux courts et fréquents pour dépenser l’énergie.',
          ],
        PetLifeStage.adult => [
            'Eau toujours accessible (prévention urinaire).',
            'Contrôle poids : les chats d’intérieur grossissent vite.',
            'Litière propre + griffoir pour limiter le stress.',
          ],
        PetLifeStage.senior => [
            'Surveille appétit, soif et mobilité.',
            'Aliment senior / rénal si prescrit.',
            'Visite véto plus fréquente après 10 ans.',
          ],
      };
    }
    return switch (stage) {
      PetLifeStage.puppy => [
          'Jeune animal : nutrition croissance + suivi véto rapproché.',
        ],
      PetLifeStage.adult => [
          'Routine stable : alimentation, hygiène, observation du comportement.',
        ],
      PetLifeStage.senior => [
          'Senior : contrôles plus fréquents et adaptation de l’environnement.',
        ],
    };
  }

  Future<BreedStats?> _findDogBreed(String breedName) async {
    final breeds = await _loadDogBreeds();
    final match = _bestMatch(breeds, breedName, (m) => m['name'] as String);
    if (match == null) return null;
    final life = match['life'] as Map<String, dynamic>?;
    final male = match['male_weight'] as Map<String, dynamic>?;
    final female = match['female_weight'] as Map<String, dynamic>?;
    final traits = match['traits'] as Map<String, dynamic>?;
    final mins = <double>[];
    final maxs = <double>[];
    for (final w in [male, female]) {
      final a = (w?['min'] as num?)?.toDouble();
      final b = (w?['max'] as num?)?.toDouble();
      if (a != null) mins.add(a);
      if (b != null) maxs.add(b);
    }
    final temps = (traits?['temperament'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return BreedStats(
      weightMin: mins.isEmpty ? null : mins.reduce((a, b) => a < b ? a : b),
      weightMax: maxs.isEmpty ? null : maxs.reduce((a, b) => a > b ? a : b),
      lifeSpanLabel: life == null
          ? null
          : '${life['min']}-${life['max']} ans',
      exerciseMinutes: (traits?['exercise_minutes'] as num?)?.toInt(),
      temperament: temps,
    );
  }

  Future<BreedStats?> _findCatBreed(String breedName) async {
    final breeds = await _loadCatBreeds();
    final match = _bestMatch(breeds, breedName, (m) => m['name'] as String);
    if (match == null) return null;
    final weight = match['weight'];
    double? min;
    double? max;
    if (weight is Map) {
      final metric = weight['metric']?.toString() ?? '';
      final parts = metric
          .split(RegExp(r'\s*-\s*'))
          .map((e) => double.tryParse(e.trim()))
          .whereType<double>()
          .toList();
      if (parts.length >= 2) {
        min = parts[0];
        max = parts[1];
      } else if (parts.length == 1) {
        min = parts[0];
        max = parts[0];
      }
    }
    final life = match['life_span']?.toString();
    final temp = match['temperament']
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return BreedStats(
      weightMin: min,
      weightMax: max,
      lifeSpanLabel: life == null || life.isEmpty ? null : '$life ans',
      temperament: temp,
    );
  }

  Future<List<Map<String, dynamic>>> _loadDogBreeds() async {
    if (_dogBreedCache != null) return _dogBreedCache!;
    final all = <Map<String, dynamic>>[];
    for (var page = 1; page <= 3; page++) {
      final uri = Uri.parse('https://dogapi.dog/api/v2/breeds').replace(
        queryParameters: {
          'page[number]': '$page',
          'page[size]': '100',
        },
      );
      final res = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) break;
      final data = jsonDecode(res.body);
      if (data is! Map) break;
      final list = data['data'];
      if (list is! List) break;
      for (final item in list) {
        if (item is! Map) continue;
        final attrs = item['attributes'];
        if (attrs is Map<String, dynamic>) {
          all.add(attrs);
        } else if (attrs is Map) {
          all.add(Map<String, dynamic>.from(attrs));
        }
      }
    }
    _dogBreedCache = all;
    return all;
  }

  Future<List<Map<String, dynamic>>> _loadCatBreeds() async {
    if (_catBreedCache != null) return _catBreedCache!;
    final res = await _client
        .get(
          Uri.parse('https://api.thecatapi.com/v1/breeds'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _catBreedCache = [];
      return _catBreedCache!;
    }
    final data = jsonDecode(res.body);
    if (data is! List) {
      _catBreedCache = [];
      return _catBreedCache!;
    }
    _catBreedCache = data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return _catBreedCache!;
  }

  Map<String, dynamic>? _bestMatch(
    List<Map<String, dynamic>> items,
    String query,
    String Function(Map<String, dynamic>) nameOf,
  ) {
    final q = _norm(query);
    if (q.isEmpty || q == '—') return null;
    Map<String, dynamic>? best;
    var bestScore = 0;
    for (final item in items) {
      final name = _norm(nameOf(item));
      if (name.isEmpty) continue;
      var score = 0;
      if (name == q) {
        score = 100;
      } else if (name.contains(q) || q.contains(name)) {
        score = 80;
      } else {
        final qParts = q.split(' ').where((e) => e.length > 2);
        final hits = qParts.where((p) => name.contains(p)).length;
        score = hits * 20;
      }
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore >= 40 ? best : null;
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9àâäéèêëïîôùûüç\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  BreedStats _localStats(String species, String breed) {
    if (species == 'Chien') {
      final b = breed.toLowerCase();
      if (b.contains('labrador') || b.contains('golden')) {
        return const BreedStats(
          weightMin: 25,
          weightMax: 36,
          lifeSpanLabel: '10-12 ans',
          exerciseMinutes: 60,
          temperament: ['amical', 'actif', 'loyal'],
        );
      }
      if (b.contains('bulldog') || b.contains('pug') || b.contains('carlin')) {
        return const BreedStats(
          weightMin: 8,
          weightMax: 25,
          lifeSpanLabel: '8-12 ans',
          exerciseMinutes: 30,
          temperament: ['calme', 'affectueux'],
        );
      }
      if (b.contains('chihuahua') || b.contains('yorkshire') || b.contains('teckel')) {
        return const BreedStats(
          weightMin: 2,
          weightMax: 9,
          lifeSpanLabel: '12-16 ans',
          exerciseMinutes: 30,
          temperament: ['vif', 'attaché'],
        );
      }
      return const BreedStats(
        weightMin: 10,
        weightMax: 30,
        lifeSpanLabel: '10-14 ans',
        exerciseMinutes: 45,
        temperament: [],
      );
    }
    if (species == 'Chat') {
      if (breed.toLowerCase().contains('maine')) {
        return const BreedStats(
          weightMin: 5,
          weightMax: 9,
          lifeSpanLabel: '10-15 ans',
          temperament: ['doux', 'sociable'],
        );
      }
      return const BreedStats(
        weightMin: 3.5,
        weightMax: 6,
        lifeSpanLabel: '12-18 ans',
        temperament: [],
      );
    }
    if (species == 'Lapin') {
      return const BreedStats(weightMin: 1.5, weightMax: 3.5, lifeSpanLabel: '8-12 ans');
    }
    return const BreedStats();
  }
}

class BreedStats {
  final double? weightMin;
  final double? weightMax;
  final String? lifeSpanLabel;
  final int? exerciseMinutes;
  final List<String> temperament;

  const BreedStats({
    this.weightMin,
    this.weightMax,
    this.lifeSpanLabel,
    this.exerciseMinutes,
    this.temperament = const [],
  });
}
