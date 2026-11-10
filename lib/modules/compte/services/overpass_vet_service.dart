import 'dart:convert';

import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';

class NearbyVetsFetchResult {
  final List<Vet> vets;
  final String source;
  final String? warning;

  const NearbyVetsFetchResult({
    required this.vets,
    required this.source,
    this.warning,
  });
}

/// Recherche de cabinets vétérinaires réels via Overpass (OpenStreetMap),
/// avec miroirs + fallback Nominatim.
class OverpassVetService {
  static const _mirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  final http.Client _client;

  OverpassVetService({http.Client? client}) : _client = client ?? http.Client();

  Future<NearbyVetsFetchResult> findNearbyDetailed({
    required double latitude,
    required double longitude,
    int radiusMeters = 25000,
    int limit = 30,
  }) async {
    Object? lastError;

    for (final endpoint in _mirrors) {
      try {
        final vets = await _queryOverpass(
          endpoint: endpoint,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          limit: limit,
        );
        return NearbyVetsFetchResult(
          vets: vets,
          source: 'Overpass / OpenStreetMap',
          warning: vets.isEmpty
              ? 'Aucun cabinet OSM dans ${radiusMeters ~/ 1000} km'
              : null,
        );
      } catch (e) {
        lastError = e;
      }
    }

    try {
      final vets = await _queryNominatimNearby(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        limit: limit,
      );
      return NearbyVetsFetchResult(
        vets: vets,
        source: 'Nominatim / OpenStreetMap',
        warning: vets.isEmpty
            ? 'Aucun résultat OSM près de cette position'
            : 'Overpass indisponible → fallback Nominatim',
      );
    } catch (e) {
      return NearbyVetsFetchResult(
        vets: const [],
        source: 'Échec OSM',
        warning:
            'OpenStreetMap inaccessible (${lastError ?? e}). Affichage seed SQLite.',
      );
    }
  }

  /// Compat : liste seule.
  Future<List<Vet>> findNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 25000,
    int limit = 30,
  }) async {
    final r = await findNearbyDetailed(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      limit: limit,
    );
    return r.vets;
  }

  Future<List<Vet>> _queryOverpass({
    required String endpoint,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int limit,
  }) async {
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="veterinary"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="veterinary"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="veterinary"](around:$radiusMeters,$latitude,$longitude);
  node["healthcare"="veterinary"](around:$radiusMeters,$latitude,$longitude);
  way["healthcare"="veterinary"](around:$radiusMeters,$latitude,$longitude);
  relation["healthcare"="veterinary"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    final res = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json',
            'User-Agent':
                'PetCareSchoolApp/1.0 (flutter; contact@petcare.local)',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 22));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Overpass HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw Exception('Réponse Overpass invalide');
    final elements = decoded['elements'];
    if (elements is! List) return const [];

    final vets = <Vet>[];
    for (final raw in elements) {
      if (raw is! Map) continue;
      final vet = _mapOverpassElement(
        Map<String, dynamic>.from(raw),
        userLat: latitude,
        userLon: longitude,
      );
      if (vet != null) vets.add(vet);
    }
    return _sortAndLimit(vets, limit);
  }

  /// Fallback si Overpass timeout : recherche Nominatim autour du point.
  Future<List<Vet>> _queryNominatimNearby({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int limit,
  }) async {
    final delta = radiusMeters / 111000.0; // ~degrés
    final left = longitude - delta;
    final right = longitude + delta;
    final top = latitude + delta;
    final bottom = latitude - delta;

    final queries = ['veterinary', 'vétérinaire', 'clinique vétérinaire'];
    final byId = <String, Vet>{};

    for (final q in queries) {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': '$limit',
          'viewbox': '$left,$top,$right,$bottom',
          'bounded': '1',
          'addressdetails': '1',
        },
      );
      final res = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'PetCareSchoolApp/1.0 (flutter; contact@petcare.local)',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) continue;
      final data = jsonDecode(res.body);
      if (data is! List) continue;
      for (final raw in data) {
        if (raw is! Map) continue;
        final vet = _mapNominatimElement(
          Map<String, dynamic>.from(raw),
          userLat: latitude,
          userLon: longitude,
        );
        if (vet != null) byId[vet.id] = vet;
      }
      if (byId.length >= 5) break;
    }

    return _sortAndLimit(byId.values.toList(), limit);
  }

  Vet? _mapOverpassElement(
    Map<String, dynamic> el, {
    required double userLat,
    required double userLon,
  }) {
    final type = el['type']?.toString() ?? 'node';
    final id = el['id'];
    if (id == null) return null;

    final tagsRaw = el['tags'];
    if (tagsRaw is! Map) return null;
    final t = Map<String, dynamic>.from(tagsRaw);

    double? lat = (el['lat'] as num?)?.toDouble();
    double? lon = (el['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) {
      final center = el['center'];
      if (center is Map) {
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }
    }
    if (lat == null || lon == null) return null;

    return _buildVet(
      id: 'osm_${type}_$id',
      name: (t['name']?.toString().trim().isNotEmpty == true)
          ? t['name'].toString().trim()
          : 'Cabinet vétérinaire',
      clinic: (t['operator']?.toString().trim().isNotEmpty == true)
          ? t['operator'].toString().trim()
          : ((t['name']?.toString().trim().isNotEmpty == true)
              ? t['name'].toString().trim()
              : 'OpenStreetMap'),
      address: _buildAddress(t),
      phone: (t['phone'] ?? t['contact:phone'] ?? '').toString(),
      specialty: _specialtyFromTags(t),
      hours: (t['opening_hours']?.toString().isNotEmpty == true)
          ? t['opening_hours'].toString()
          : 'Voir OSM',
      lat: lat,
      lon: lon,
      userLat: userLat,
      userLon: userLon,
    );
  }

  Vet? _mapNominatimElement(
    Map<String, dynamic> el, {
    required double userLat,
    required double userLon,
  }) {
    final osmType = el['osm_type']?.toString() ?? 'node';
    final osmId = el['osm_id'];
    if (osmId == null) return null;
    final lat = double.tryParse(el['lat']?.toString() ?? '');
    final lon = double.tryParse(el['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final name = (el['name']?.toString().trim().isNotEmpty == true)
        ? el['name'].toString().trim()
        : (el['display_name']?.toString().split(',').first.trim() ??
            'Cabinet vétérinaire');

    return _buildVet(
      id: 'osm_${osmType}_$osmId',
      name: name,
      clinic: name,
      address: el['display_name']?.toString() ?? 'OpenStreetMap',
      phone: '',
      specialty: 'Généraliste',
      hours: 'Voir OSM',
      lat: lat,
      lon: lon,
      userLat: userLat,
      userLon: userLon,
    );
  }

  Vet _buildVet({
    required String id,
    required String name,
    required String clinic,
    required String address,
    required String phone,
    required String specialty,
    required String hours,
    required double lat,
    required double lon,
    required double userLat,
    required double userLon,
  }) {
    final km = GeocodingService.distanceKm(
      lat1: userLat,
      lon1: userLon,
      lat2: lat,
      lon2: lon,
    );
    return Vet(
      id: id,
      name: name,
      specialty: specialty,
      clinic: clinic,
      address: address.isEmpty ? 'OpenStreetMap' : address,
      rating: 4.5,
      reviews: 0,
      distance: _formatKm(km),
      experience: 0,
      availableToday: true,
      color: const Color(0xFF4C7CF6),
      price: 'Sur place',
      services: const ['Consultation', 'Vaccination'],
      hoursWeekdays: hours,
      hoursSaturday: 'Voir OSM',
      phone: phone,
      latitude: lat,
      longitude: lon,
    );
  }

  String _specialtyFromTags(Map<String, dynamic> t) {
    final raw = [
      t['veterinary']?.toString() ?? '',
      t['animal']?.toString() ?? '',
      t['description']?.toString() ?? '',
    ].join(' ').toLowerCase();
    if (raw.contains('exotic') ||
        raw.contains('nac') ||
        raw.contains('rabbit') ||
        raw.contains('bird')) {
      return 'NAC';
    }
    if (raw.contains('dent')) return 'Dentaire';
    if (raw.contains('surg') || raw.contains('chir')) return 'Chirurgie';
    return 'Généraliste';
  }

  String _buildAddress(Map<String, dynamic> t) {
    final street = [
      t['addr:housenumber']?.toString(),
      t['addr:street']?.toString(),
    ].where((e) => e != null && e.trim().isNotEmpty).join(' ');
    final city = [
      t['addr:postcode']?.toString(),
      t['addr:city']?.toString() ?? t['addr:town']?.toString(),
    ].where((e) => e != null && e.trim().isNotEmpty).join(' ');
    if (street.isEmpty && city.isEmpty) {
      return t['addr:full']?.toString() ?? '';
    }
    if (street.isEmpty) return city;
    if (city.isEmpty) return street;
    return '$street, $city';
  }

  List<Vet> _sortAndLimit(List<Vet> vets, int limit) {
    vets.sort(
        (a, b) => _parseKm(a.distance).compareTo(_parseKm(b.distance)));
    if (vets.length <= limit) return vets;
    return vets.sublist(0, limit);
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
}
