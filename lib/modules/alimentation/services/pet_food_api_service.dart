import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

class PetFoodSearchResult {
  final List<PetFoodProduct> products;

  /// `true` si l'API n'a pas répondu : résultats tirés du cache SQLite.
  final bool fromCache;

  const PetFoodSearchResult(this.products, {this.fromCache = false});
}

/// API externe du module Alimentation : **Open Pet Food Facts**
/// (https://world.openpetfoodfacts.org) — base ouverte de produits pour
/// chiens et chats, sans clé (licence ODbL).
///
/// Chaque produit reçu est mis en cache dans `pet_food_cache` : recherche et
/// fiches restent disponibles hors ligne.
class PetFoodApiService {
  static const host = 'world.openpetfoodfacts.org';
  static const _fields =
      'code,product_name,product_name_fr,brands,quantity,'
      'image_front_small_url,image_small_url,categories_tags,nutriments,'
      'ingredients_text,ingredients_text_fr';

  /// L'API demande un User-Agent identifiant l'application.
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'PetCare/1.0 (Flutter student project)',
  };

  final http.Client _client;
  final _db = AppDatabase.instance;

  PetFoodApiService({http.Client? client}) : _client = client ?? http.Client();

  /// `Chien` → `dog`, `Chat` → `cat`, sinon null (pas de filtre).
  static String? speciesTag(String petSpecies) => switch (petSpecies) {
    'Chien' => 'dog',
    'Chat' => 'cat',
    _ => null,
  };

  /// Recherche par nom / marque, ou par code-barres si la saisie est
  /// numérique. En cas d'échec réseau : recherche dans le cache.
  Future<PetFoodSearchResult> search(String query, {String? species}) async {
    final q = query.trim();
    if (q.isEmpty) return const PetFoodSearchResult([]);
    if (RegExp(r'^\d{8,14}$').hasMatch(q)) {
      final p = await getByCode(q);
      return PetFoodSearchResult(p == null ? const [] : [p]);
    }
    try {
      final params = {
        'search_terms': q,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '25',
        'fields': _fields,
        if (species != null) ...{
          'tagtype_0': 'categories',
          'tag_contains_0': 'contains',
          'tag_0': '$species-food',
        },
      };
      final res = await _client
          .get(Uri.https(host, '/cgi/search.pl', params), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw http.ClientException('${res.statusCode}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final products = [
        for (final raw in (data['products'] as List? ?? const []))
          if (raw is Map<String, dynamic>) productFromJson(raw),
      ].whereType<PetFoodProduct>().toList();
      await _cacheAll(products);
      return PetFoodSearchResult(products);
    } catch (_) {
      return PetFoodSearchResult(
        await searchCache(q, species: species),
        fromCache: true,
      );
    }
  }

  /// Fiche produit : cache d'abord (< 30 jours), sinon API.
  Future<PetFoodProduct?> getByCode(String code) async {
    final cached = await _cached(code);
    if (cached != null) return cached;
    try {
      final res = await _client
          .get(
            Uri.https(host, '/api/v2/product/$code.json', {'fields': _fields}),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return await _cached(code, anyAge: true);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 1 || data['product'] is! Map) return null;
      final p = productFromJson({
        ...data['product'] as Map<String, dynamic>,
        'code': code,
      });
      if (p != null) await _cacheAll([p]);
      return p;
    } catch (_) {
      return await _cached(code, anyAge: true);
    }
  }

  /// Recherche hors ligne : chaque mot doit apparaître dans marque + nom.
  Future<List<PetFoodProduct>> searchCache(
    String query, {
    String? species,
  }) async {
    final words = normalizeText(
      query,
    ).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final db = await _db.database;
    final where = [
      for (final _ in words) 'search_text LIKE ?',
      if (species != null) "(species = ? OR species = '')",
    ].join(' AND ');
    final rows = await db.query(
      'pet_food_cache',
      where: where,
      whereArgs: [for (final w in words) '%$w%', ?species],
      orderBy: 'fetched_at DESC',
      limit: 25,
    );
    return rows.map(PetFoodProduct.fromMap).toList();
  }

  Future<PetFoodProduct?> _cached(String code, {bool anyAge = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'pet_food_cache',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final fetched = DateTime.tryParse(rows.first['fetched_at'] as String);
    final fresh =
        fetched != null &&
        DateTime.now().difference(fetched) < const Duration(days: 30);
    return (fresh || anyAge) ? PetFoodProduct.fromMap(rows.first) : null;
  }

  Future<void> _cacheAll(List<PetFoodProduct> products) async {
    if (products.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'pet_food_cache',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// JSON Open Pet Food Facts → produit (null si sans nom exploitable).
  static PetFoodProduct? productFromJson(Map<String, dynamic> j) {
    String str(String k) => (j[k] ?? '').toString().trim();
    final code = str('code');
    final name = str('product_name_fr').isNotEmpty
        ? str('product_name_fr')
        : str('product_name');
    if (code.isEmpty || name.isEmpty) return null;
    final categories = [
      for (final c in (j['categories_tags'] as List? ?? const [])) c.toString(),
    ];
    final dog = categories.any((c) => c.contains('dog-food'));
    final cat = categories.any((c) => c.contains('cat-food'));
    final kcal = estimateKcalPer100g(
      (j['nutriments'] as Map?)?.cast<String, dynamic>() ?? const {},
      categories,
      packGrams: parseGrams(str('quantity')),
    );
    return PetFoodProduct(
      code: code,
      name: name,
      brand: str('brands').split(',').first.trim(),
      imageUrl: str('image_front_small_url').isNotEmpty
          ? str('image_front_small_url')
          : str('image_small_url'),
      quantity: str('quantity'),
      species: dog == cat ? '' : (dog ? 'dog' : 'cat'),
      kcalPer100g: kcal?.$1,
      kcalEstimated: kcal?.$2 ?? false,
      ingredients: str('ingredients_text_fr').isNotEmpty
          ? str('ingredients_text_fr')
          : str('ingredients_text'),
    );
  }

  /// kcal / 100 g et `true` si estimé.
  ///
  /// 1. Valeur déclarée (kcal, sinon kJ ÷ 4,184) si plausible pour le type
  ///    d'aliment (sec : 250–650, humide : 40–200).
  /// 2. Sinon estimation par la formule d'Atwater modifiée (NRC, aliments
  ///    pour animaux) depuis l'analyse garantie :
  ///    3,5 × protéines + 8,5 × matières grasses + 3,5 × ENA, où
  ///    ENA = 100 − protéines − MG − cellulose − cendres − humidité.
  ///    Valeurs manquantes : moyennes d'un aliment sec ou humide.
  ///
  /// Les données saisies par la communauté contiennent des erreurs (virgule
  /// décalée, valeurs pour 10 g…) : une analyse impossible pour le type
  /// d'aliment (croquettes à 2,7 % de protéines) renvoie null plutôt qu'un
  /// chiffre faux.
  static (double, bool)? estimateKcalPer100g(
    Map<String, dynamic> n,
    List<String> categories, {
    int? packGrams,
  }) {
    double? v(String k) {
      final x = n[k];
      final d = x is num ? x.toDouble() : double.tryParse('$x');
      return (d == null || d <= 0) ? null : d;
    }

    final measuredMoisture = v('moisture_100g');
    // Type d'aliment : catégorie, sinon humidité, sinon taille du paquet
    // (≥ 1 kg = croquettes ; les pâtées sont en boîtes / sachets).
    bool? wet;
    if (categories.any((c) => c.contains('wet'))) {
      wet = true;
    } else if (categories.any((c) => c.contains('dry'))) {
      wet = false;
    } else if (measuredMoisture != null) {
      wet = measuredMoisture > 50;
    } else if (packGrams != null && packGrams >= 1000) {
      wet = false;
    }

    bool plausible(double k) => switch (wet) {
      true => k >= 40 && k <= 200,
      false => k >= 250 && k <= 650,
      null => k >= 40 && k <= 650,
    };

    final declared = v('energy-kcal_100g');
    if (declared != null && plausible(declared)) return (declared, false);
    final kj = v('energy-kj_100g') ?? v('energy_100g');
    if (kj != null && plausible(kj / 4.184)) return (kj / 4.184, false);

    final protein = v('crude-protein_100g') ?? v('proteins_100g');
    final fat = v('crude-fat_100g') ?? v('fat_100g');
    if (protein == null || fat == null) return null;
    final isWet = wet ?? protein < 15;
    // Analyse impossible pour ce type d'aliment → donnée erronée.
    if (isWet ? protein < 3 : protein < 15) return null;
    final fibre = v('crude-fibre_100g') ?? v('fiber_100g') ?? (isWet ? 0.5 : 3);
    final ash = v('crude-ash_100g') ?? (isWet ? 2.5 : 7);
    final moisture = measuredMoisture ?? (isWet ? 78 : 10);
    final nfe = 100 - protein - fat - fibre - ash - moisture;
    final kcal = 3.5 * protein + 8.5 * fat + 3.5 * (nfe < 0 ? 0 : nfe);
    return plausible(kcal) ? (kcal, true) : null;
  }
}
