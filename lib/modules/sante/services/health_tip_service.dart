import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_example/core/data/app_database.dart';

class HealthTip {
  final String text;
  final String source;
  final String sourceUrl;
  final bool fromCache;
  final double? temperatureC;
  final int? weatherCode;

  const HealthTip({
    required this.text,
    required this.source,
    this.sourceUrl = 'https://open-meteo.com/',
    this.fromCache = false,
    this.temperatureC,
    this.weatherCode,
  });
}

/// Module Santé — conseil santé selon la météo (Open-Meteo, sans clé).
/// GET HTTP → conseil affiché ; hors ligne → cache SQLite.
class HealthTipService {
  final http.Client _client;
  final _db = AppDatabase.instance;

  /// Paris par défaut (démo scolaire).
  static const _lat = 48.8566;
  static const _lon = 2.3522;
  static const _place = 'Paris';

  HealthTipService({http.Client? client}) : _client = client ?? http.Client();

  Future<HealthTip> getTipOfDay(String species) async {
    try {
      final online = await _fetchWeatherTip(species);
      await _cacheTip(species, online.text, online.source);
      return online;
    } catch (_) {
      final cached = await _latestCache(species);
      if (cached != null) return cached;
      return _localFallback(species);
    }
  }

  Future<HealthTip> _fetchWeatherTip(String species) async {
    final uri = Uri.parse('https://api.open-meteo.com/v1/forecast').replace(
      queryParameters: {
        'latitude': '$_lat',
        'longitude': '$_lon',
        'current': 'temperature_2m,weather_code,relative_humidity_2m',
        'timezone': 'Europe/Paris',
      },
    );
    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Open-Meteo HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! Map) throw Exception('Réponse météo invalide');
    final current = data['current'];
    if (current is! Map) throw Exception('Données current absentes');

    final temp = (current['temperature_2m'] as num?)?.toDouble();
    final code = (current['weather_code'] as num?)?.toInt();
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt();
    if (temp == null) throw Exception('Température absente');

    final advice = _adviceFor(
      species: species,
      tempC: temp,
      weatherCode: code ?? 0,
      humidity: humidity,
    );
    final sky = _skyLabel(code ?? 0);
    final text =
        'À $_place : ${temp.toStringAsFixed(1)}°C · $sky'
        '${humidity != null ? ' · humidité $humidity%' : ''}.\n$advice';

    return HealthTip(
      text: text,
      source: 'Open-Meteo API',
      sourceUrl: 'https://open-meteo.com/',
      temperatureC: temp,
      weatherCode: code,
    );
  }

  String _adviceFor({
    required String species,
    required double tempC,
    required int weatherCode,
    int? humidity,
  }) {
    final pet = species.toLowerCase();
    final isDog = pet == 'chien';
    final isCat = pet == 'chat';
    final isOutdoorSensitive =
        isDog || pet == 'lapin' || pet == 'oiseau' || pet == 'autre';

    if (tempC >= 30) {
      if (isDog) {
        return 'Canicule : sorties très tôt / tard, eau à volonté, évite l’asphalte brûlant (coussinets).';
      }
      if (isCat) {
        return 'Forte chaleur : laisse de l’eau fraîche accessible et un endroit ombragé / aéré.';
      }
      return 'Chaleur élevée : hydrate bien ton animal et limite l’exposition au soleil.';
    }
    if (tempC >= 25) {
      return isDog
          ? 'Il fait chaud : raccourcis la balade, emporte de l’eau, surveille le souffle.'
          : 'Température élevée : vérifie que ton animal peut s’hydrater facilement.';
    }
    if (tempC <= 0) {
      return isDog
          ? 'Gel : sorties courtes, protège les pattes si besoin, sèche bien au retour.'
          : 'Froid intense : évite les courants d’air et garde un couchage au chaud.';
    }
    if (tempC <= 5) {
      return isOutdoorSensitive
          ? 'Froid : limite le temps dehors et surveille les tremblements.'
          : 'Il fait frais : assure un environnement confortable à l’intérieur.';
    }
    if (weatherCode >= 61 && weatherCode < 70) {
      return 'Pluie : sèche ton animal au retour pour éviter refroidissements / mycoses des pattes.';
    }
    if (weatherCode >= 71 && weatherCode < 80) {
      return 'Neige / verglas : attention aux salages (pattes) et aux glissades.';
    }
    if (humidity != null && humidity >= 85 && tempC >= 20) {
      return 'Air très humide : risque d’inconfort ; aère sans courant d’air violent.';
    }
    if (isDog) {
      return 'Conditions favorables : bonne fenêtre pour une balade et un contrôle rapide des coussinets.';
    }
    if (isCat) {
      return 'Météo calme : moment idéal pour jouer un peu et vérifier appétit / litière.';
    }
    return 'Conditions correctes : jour idéal pour une petite séance de jeu / observation.';
  }

  String _skyLabel(int code) {
    if (code == 0) return 'ciel dégagé';
    if (code <= 3) return 'partiellement nuageux';
    if (code <= 48) return 'brouillard';
    if (code <= 57) return 'bruine';
    if (code <= 67) return 'pluie';
    if (code <= 77) return 'neige';
    if (code <= 82) return 'averses';
    if (code >= 95) return 'orage';
    return 'variable';
  }

  Future<void> _cacheTip(String species, String text, String source) async {
    final db = await _db.database;
    await db.insert('health_tips_cache', {
      'species': species,
      'tip_text': text,
      'source': source,
      'fetched_at': DateTime.now().toIso8601String(),
    });
    await db.rawDelete('''
      DELETE FROM health_tips_cache
      WHERE species = ? AND id NOT IN (
        SELECT id FROM health_tips_cache
        WHERE species = ?
        ORDER BY id DESC
        LIMIT 20
      )
    ''', [species, species]);
  }

  Future<HealthTip?> _latestCache(String species) async {
    final db = await _db.database;
    final rows = await db.query(
      'health_tips_cache',
      where: 'species = ?',
      whereArgs: [species],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthTip(
      text: rows.first['tip_text'] as String,
      source: '${rows.first['source']} (cache SQLite)',
      sourceUrl: 'https://open-meteo.com/',
      fromCache: true,
    );
  }

  HealthTip _localFallback(String species) {
    final tip = switch (species) {
      'Chien' =>
        'Sans météo : eau fraîche, coussinets propres après balade, vermifuge à jour.',
      'Chat' =>
        'Sans météo : litière propre, eau accessible, surveillance appétit / vomissements.',
      _ =>
        'Sans météo : pèse régulièrement ton animal et note tout symptôme inhabituel.',
    };
    return HealthTip(
      text: tip,
      source: 'Conseil local (SQLite)',
      sourceUrl: 'https://open-meteo.com/',
      fromCache: true,
    );
  }
}
