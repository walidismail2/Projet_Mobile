import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class GeoPoint {
  final double latitude;
  final double longitude;
  final String displayName;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

/// Module Compte — géocodage d’adresses via Nominatim (OpenStreetMap).
/// Accepte aussi des coordonnées : `36.6833, 10.3007` ou `36,6833, 10,3007`.
/// https://nominatim.openstreetmap.org/
class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'PetCareSchoolApp/1.0 (flutter; contact@petcare.local)',
  };

  Future<GeoPoint> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      throw Exception('Adresse vide');
    }

    final coords = tryParseCoordinates(query);
    if (coords != null) {
      final label = await _reverseLabel(coords.$1, coords.$2) ??
          '${coords.$1.toStringAsFixed(5)}, ${coords.$2.toStringAsFixed(5)}';
      return GeoPoint(
        latitude: coords.$1,
        longitude: coords.$2,
        displayName: label,
      );
    }

    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '1',
        'addressdetails': '0',
      },
    );

    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Nominatim HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    if (data is! List || data.isEmpty) {
      throw Exception('Adresse introuvable');
    }
    final first = data.first;
    if (first is! Map) throw Exception('Réponse Nominatim invalide');

    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      throw Exception('Coordonnées invalides');
    }

    return GeoPoint(
      latitude: lat,
      longitude: lon,
      displayName: first['display_name']?.toString() ?? query,
    );
  }

  /// Parse `lat, lon` avec point ou virgule décimale.
  /// Ex. `36.6833141, 10.3006583` ou `36,6833141, 10,3006583`.
  static (double, double)? tryParseCoordinates(String raw) {
    final text = raw.trim();

    // Deux nombres décimaux séparés par virgule/point-virgule/espace.
    final match = RegExp(
      r'^\s*(-?\d+[.,]\d+)\s*[,;\s]\s*(-?\d+[.,]\d+)\s*$',
    ).firstMatch(text);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final lon = double.tryParse(match.group(2)!.replaceAll(',', '.'));
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return (lat, lon);
  }

  Future<String?> _reverseLabel(double lat, double lon) async {
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': '$lat',
          'lon': '$lon',
          'format': 'json',
          'zoom': '16',
        },
      );
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      final name = data['display_name']?.toString();
      if (name == null || name.isEmpty) return null;
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Distance à vol d’oiseau (km) — formule de Haversine.
  static double distanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}
