import 'package:flutter/material.dart' show Color;
import 'package:sqflite/sqflite.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/modules/compte/data/vet_seed.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';
import 'package:flutter_example/modules/compte/services/overpass_vet_service.dart';

class NearbySearchBundle {
  final List<Vet> vets;
  final int osmCount;
  final String source;
  final String? warning;

  const NearbySearchBundle({
    required this.vets,
    required this.osmCount,
    required this.source,
    this.warning,
  });
}

class VetRepository {
  final AppDatabase _db = AppDatabase.instance;
  final OverpassVetService _overpass = OverpassVetService();

  Future<List<Vet>> getVets({String? specialty}) async {
    await _ensureSeeded();
    final db = await _db.database;
    final rows = specialty == null || specialty == 'Tous'
        ? await db.query('vets_cache', orderBy: 'rating DESC')
        : await db.query(
            'vets_cache',
            where: 'specialty = ?',
            whereArgs: [specialty],
            orderBy: 'rating DESC',
          );
    return rows.map(Vet.fromCacheMap).toList();
  }

  Future<Vet?> getById(String id) async {
    await _ensureSeeded();
    final db = await _db.database;
    final rows = await db.query(
      'vets_cache',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Vet.fromCacheMap(rows.first);
  }

  /// Met à jour / crée la fiche annuaire d’un compte véto connecté.
  Future<void> ensureDirectoryListing(AppUser user) async {
    if (!user.isVet) return;
    final existing = await getById(user.id);
    if (existing != null) {
      await upsertDirectoryVet(Vet(
        id: user.id,
        name: user.name,
        specialty: existing.specialty,
        clinic: existing.clinic,
        address: existing.address,
        rating: existing.rating,
        reviews: existing.reviews,
        distance: existing.distance,
        experience: existing.experience,
        availableToday: existing.availableToday,
        color: existing.color,
        price: existing.price,
        image: existing.image,
        services: existing.services,
        hoursWeekdays: existing.hoursWeekdays,
        hoursSaturday: existing.hoursSaturday,
        phone: user.phone.isNotEmpty ? user.phone : existing.phone,
      ));
      return;
    }
    await upsertDirectoryVet(Vet(
      id: user.id,
      name: user.name,
      specialty: 'Généraliste',
      clinic: 'Cabinet privé',
      address: user.phone.isEmpty
          ? 'Coordonnées via l’app'
          : 'Tél. ${user.phone}',
      rating: 5.0,
      reviews: 0,
      distance: '—',
      experience: 1,
      availableToday: true,
      color: const Color(0xFF4C7CF6),
      price: 'Sur devis',
      services: const ['Consultation', 'Vaccination'],
      phone: user.phone,
    ));
  }

  Future<void> upsertDirectoryVet(Vet vet) async {
    final db = await _db.database;
    await db.insert(
      'vets_cache',
      vet.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCoordinates({
    required String vetId,
    required double latitude,
    required double longitude,
  }) async {
    final db = await _db.database;
    await db.update(
      'vets_cache',
      {'latitude': latitude, 'longitude': longitude},
      where: 'id = ?',
      whereArgs: [vetId],
    );
  }

  /// Seed local + cabinets OSM (Overpass / Nominatim) autour de la position.
  Future<NearbySearchBundle> getNearbyCombined({
    required double latitude,
    required double longitude,
    String? specialty,
    int radiusMeters = 25000,
  }) async {
    final local = await getVets(specialty: specialty);
    final withDistance = local.map((v) {
      if (!v.hasCoordinates) return v;
      final km = GeocodingService.distanceKm(
        lat1: latitude,
        lon1: longitude,
        lat2: v.latitude!,
        lon2: v.longitude!,
      );
      return Vet(
        id: v.id,
        name: v.name,
        specialty: v.specialty,
        clinic: v.clinic,
        address: v.address,
        rating: v.rating,
        reviews: v.reviews,
        distance: _formatKm(km),
        experience: v.experience,
        availableToday: v.availableToday,
        color: v.color,
        price: v.price,
        image: v.image,
        services: v.services,
        hoursWeekdays: v.hoursWeekdays,
        hoursSaturday: v.hoursSaturday,
        phone: v.phone,
        latitude: v.latitude,
        longitude: v.longitude,
      );
    }).toList();

    // Exclure les vieux seed trop loin (> 80 km) pour ne pas masquer OSM.
    final localNear = withDistance.where((v) {
      if (!v.hasCoordinates) return false;
      return _parseKm(v.distance) <= 80;
    }).toList();

    final osmResult = await _overpass.findNearbyDetailed(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    for (final v in osmResult.vets) {
      await upsertDirectoryVet(v);
    }

    final byId = <String, Vet>{};
    for (final v in localNear) {
      byId[v.id] = v;
    }
    for (final v in osmResult.vets) {
      if (specialty != null &&
          specialty != 'Tous' &&
          v.specialty != specialty) {
        continue;
      }
      byId[v.id] = v;
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final osmA = a.id.startsWith('osm_') ? 0 : 1;
        final osmB = b.id.startsWith('osm_') ? 0 : 1;
        if (osmA != osmB) return osmA.compareTo(osmB);
        return _parseKm(a.distance).compareTo(_parseKm(b.distance));
      });

    return NearbySearchBundle(
      vets: merged,
      osmCount: osmResult.vets.length,
      source: osmResult.source,
      warning: osmResult.warning,
    );
  }

  /// Retourne le vétérinaire le plus proche (OSM + seed).
  Future<NearestVetSuggestion?> findNearest({
    required double latitude,
    required double longitude,
  }) async {
    final bundle = await getNearbyCombined(
      latitude: latitude,
      longitude: longitude,
    );
    NearestVetSuggestion? best;
    for (final vet in bundle.vets) {
      if (!vet.hasCoordinates) continue;
      final km = GeocodingService.distanceKm(
        lat1: latitude,
        lon1: longitude,
        lat2: vet.latitude!,
        lon2: vet.longitude!,
      );
      if (best == null || km < best.distanceKm) {
        best = NearestVetSuggestion(vet: vet, distanceKm: km);
      }
    }
    return best;
  }

  String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  double _parseKm(String label) {
    final cleaned = label.toLowerCase().replaceAll(',', '.');
    if (cleaned.contains('m') && !cleaned.contains('km')) {
      final n = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
      return (n ?? 999999) / 1000.0;
    }
    final n = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
    return n ?? 999999;
  }

  Future<void> _ensureSeeded() async {
    final db = await _db.database;
    for (final v in kSeedVets) {
      await db.insert(
        'vets_cache',
        v.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (v.hasCoordinates) {
        await db.update(
          'vets_cache',
          {
            'latitude': v.latitude,
            'longitude': v.longitude,
          },
          where: 'id = ?',
          whereArgs: [v.id],
        );
      }
    }
    // Garantit l’adresse ESPRIT pour la démo Nominatim.
    await db.update(
      'vets_cache',
      {
        'name': 'Dr. Azziz Ben Sghaier',
        'specialty': 'Généraliste',
        'clinic': 'Clinique ESPRIT Vet',
        'address': 'ESPRIT, Ariana, Tunisie',
        'phone': '+216 70 000 000',
        'latitude': 36.8982,
        'longitude': 10.1897,
      },
      where: 'id = ?',
      whereArgs: ['v5'],
    );
  }
}
