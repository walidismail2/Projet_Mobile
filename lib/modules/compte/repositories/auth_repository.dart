import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show Color;

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/services/app_exception.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';
import 'package:flutter_example/modules/compte/repositories/user_repository.dart';
import 'package:flutter_example/modules/compte/repositories/vet_repository.dart';

class AuthRepository {
  /// Compte admin seedé (gestion boutique accessoires uniquement).
  static const adminEmail = 'admin@petcare.local';
  static const adminPassword = 'admin123';

  final Session _session = Session.instance;
  final UserRepository _users = UserRepository();
  final VetRepository _vets = VetRepository();

  /// Crée l’admin s’il n’existe pas encore.
  Future<void> ensureAdminSeeded() async {
    if (await _users.emailExists(adminEmail)) return;
    final salt = _randomSalt();
    await _users.insertWithPassword(
      user: const AppUser(
        id: 'u_admin_petcare',
        name: 'Administrateur',
        email: adminEmail,
        role: UserRole.admin,
      ),
      passwordHash: _hashPassword(adminPassword, salt),
      passwordSalt: salt,
    );
  }

  Future<AppUser> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final normalized = email.trim().toLowerCase();
    final row = await _users.getAuthRowByEmail(normalized);
    if (row == null) {
      throw AppException('Aucun compte pour cet e-mail. Inscris-toi d’abord.');
    }
    final hash = _hashPassword(password, row.salt);
    if (hash != row.passwordHash) {
      throw AppException('E-mail ou mot de passe incorrect.');
    }
    final user = row.user;
    if (user.isVet) {
      await _vets.ensureDirectoryListing(user);
    }
    await _session.signIn(user, remember: remember);
    return user;
  }

  /// Crée le compte. Pour un propriétaire avec adresse, géocode (Nominatim)
  /// et renvoie le vétérinaire le plus proche si possible.
  Future<NearestVetSuggestion?> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    UserRole role = UserRole.owner,
    String specialty = 'Généraliste',
    String clinic = '',
    String address = '',
    List<String> services = const [],
    String hoursWeekdays = '08:30 – 19:00',
    String hoursSaturday = '09:00 – 13:00',
  }) async {
    if (role == UserRole.admin) {
      throw AppException('Impossible de créer un compte administrateur.');
    }
    final normalized = email.trim().toLowerCase();
    if (await _users.emailExists(normalized)) {
      throw AppException('Cet e-mail est déjà utilisé.');
    }
    if (password.length < 6) {
      throw AppException('Mot de passe trop faible (6 caractères min.).');
    }

    final trimmedAddress = address.trim();
    double? lat;
    double? lon;
    NearestVetSuggestion? nearest;

    if (role == UserRole.owner && trimmedAddress.isNotEmpty) {
      try {
        final point =
            await GeocodingService().geocodeAddress(trimmedAddress);
        lat = point.latitude;
        lon = point.longitude;
        nearest = await _vets.findNearest(
          latitude: lat,
          longitude: lon,
        );
      } catch (_) {
        // Compte créé quand même si Nominatim échoue.
      }
    }

    final salt = _randomSalt();
    final user = AppUser(
      id: _newUserId(),
      name: name.trim(),
      email: normalized,
      phone: phone.trim(),
      role: role,
      address: trimmedAddress,
      latitude: lat,
      longitude: lon,
    );

    await _users.insertWithPassword(
      user: user,
      passwordHash: _hashPassword(password, salt),
      passwordSalt: salt,
    );

    if (role == UserRole.vet) {
      final vetServices = services.isEmpty
          ? <String>['Consultation', 'Vaccination']
          : services;
      final clinicName =
          clinic.trim().isEmpty ? 'Cabinet privé' : clinic.trim();
      final vetAddress = trimmedAddress.isEmpty
          ? (phone.trim().isEmpty
              ? 'Coordonnées via l’app'
              : 'Tél. ${phone.trim()}')
          : trimmedAddress;

      double? vetLat;
      double? vetLon;
      try {
        if (trimmedAddress.isNotEmpty) {
          final point =
              await GeocodingService().geocodeAddress(trimmedAddress);
          vetLat = point.latitude;
          vetLon = point.longitude;
        }
      } catch (_) {}

      await _vets.upsertDirectoryVet(Vet(
        id: user.id,
        name: user.name,
        specialty: specialty.trim().isEmpty ? 'Généraliste' : specialty.trim(),
        clinic: clinicName,
        address: vetAddress,
        rating: 5.0,
        reviews: 0,
        distance: '—',
        experience: 1,
        availableToday: true,
        color: const Color(0xFF4C7CF6),
        price: 'Sur devis',
        services: vetServices,
        hoursWeekdays: hoursWeekdays.trim(),
        hoursSaturday: hoursSaturday.trim(),
        phone: user.phone,
        latitude: vetLat,
        longitude: vetLon,
      ));
    }

    return nearest;
  }

  Future<void> logout() async {
    await _session.signOut();
  }

  /// Change le mot de passe de l’utilisateur connecté (SQLite).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _session.currentUser;
    if (user == null) {
      throw AppException('Non connecté');
    }
    if (newPassword.length < 6) {
      throw AppException('Nouveau mot de passe trop faible (6 caractères min.).');
    }
    if (currentPassword == newPassword) {
      throw AppException('Le nouveau mot de passe doit être différent.');
    }

    final row = await _users.getAuthRowById(user.id);
    if (row == null) {
      throw AppException('Compte introuvable');
    }
    final currentHash = _hashPassword(currentPassword, row.salt);
    if (currentHash != row.passwordHash) {
      throw AppException('Mot de passe actuel incorrect.');
    }

    final salt = _randomSalt();
    await _users.updatePassword(
      userId: user.id,
      passwordHash: _hashPassword(newPassword, salt),
      passwordSalt: salt,
    );
  }

  String _newUserId() =>
      'u_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

  String _randomSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }
}
