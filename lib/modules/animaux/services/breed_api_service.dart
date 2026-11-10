import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_example/core/services/app_exception.dart';

class BreedInfo {
  final String name;
  final String? dogSlug;
  final String? dogSubSlug;
  final String? catId;

  const BreedInfo({
    required this.name,
    this.dogSlug,
    this.dogSubSlug,
    this.catId,
  });
}

/// APIs externes pour le module Animaux (valeur ajoutée HTTP).
/// - Chiens : Dog CEO — https://dog.ceo/dog-api/
/// - Chats : The Cat API — https://thecatapi.com/
class BreedApiService {
  final http.Client _client;

  BreedApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<BreedInfo>> fetchBreeds(String species) async {
    if (species == 'Chien') return _fetchDogBreeds();
    if (species == 'Chat') return _fetchCatBreeds();
    return const [];
  }

  Future<String?> fetchBreedImage(BreedInfo breed) async {
    try {
      if (breed.dogSlug != null) {
        final path = breed.dogSubSlug == null
            ? 'https://dog.ceo/api/breed/${breed.dogSlug}/images/random'
            : 'https://dog.ceo/api/breed/${breed.dogSlug}/${breed.dogSubSlug}/images/random';
        final res = await _client
            .get(Uri.parse(path), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode < 200 || res.statusCode >= 300) return null;
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          return data['message']?.toString();
        }
      }
      if (breed.catId != null) {
        final uri = Uri.parse('https://api.thecatapi.com/v1/images/search')
            .replace(queryParameters: {'breed_ids': breed.catId, 'limit': '1'});
        final res = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode < 200 || res.statusCode >= 300) return null;
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          return data.first['url']?.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<BreedInfo>> _fetchDogBreeds() async {
    try {
      final res = await _client
          .get(
            Uri.parse('https://dog.ceo/api/breeds/list/all'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AppException('Dog CEO HTTP ${res.statusCode}',
            statusCode: res.statusCode);
      }
      final data = jsonDecode(res.body);
      if (data is! Map || data['status'] != 'success') {
        throw AppException('Réponse Dog CEO invalide');
      }
      final message = data['message'];
      if (message is! Map) throw AppException('Liste de races invalide');

      final breeds = <BreedInfo>[];
      message.forEach((key, value) {
        final slug = key.toString();
        final subs = value is List ? value.map((e) => e.toString()).toList() : <String>[];
        if (subs.isEmpty) {
          breeds.add(BreedInfo(name: _titleCase(slug), dogSlug: slug));
        } else {
          for (final sub in subs) {
            breeds.add(BreedInfo(
              name: _titleCase('$sub $slug'),
              dogSlug: slug,
              dogSubSlug: sub,
            ));
          }
        }
      });
      breeds.sort((a, b) => a.name.compareTo(b.name));
      return breeds;
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException('Impossible de charger les races (Dog CEO).');
    }
  }

  Future<List<BreedInfo>> _fetchCatBreeds() async {
    try {
      final res = await _client
          .get(
            Uri.parse('https://api.thecatapi.com/v1/breeds'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AppException('The Cat API HTTP ${res.statusCode}',
            statusCode: res.statusCode);
      }
      final data = jsonDecode(res.body);
      if (data is! List) throw AppException('Réponse Cat API invalide');

      final breeds = data
          .map((e) {
            if (e is! Map) return null;
            final name = e['name']?.toString();
            final id = e['id']?.toString();
            if (name == null || name.isEmpty || id == null) return null;
            return BreedInfo(name: name, catId: id);
          })
          .whereType<BreedInfo>()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return breeds;
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException('Impossible de charger les races (The Cat API).');
    }
  }

  String _titleCase(String raw) {
    return raw
        .split(RegExp(r'[\s_-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
