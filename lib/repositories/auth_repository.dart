import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/session.dart';
import '../models/models.dart';
import '../services/app_exception.dart';
import 'vet_repository.dart';

class EmailNotVerifiedException extends AppException {
  EmailNotVerifiedException()
      : super(
          'E-mail non confirmé. Ouvre le lien reçu par mail, puis reconnecte-toi.',
        );
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Session _session = Session.instance;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AppUser> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        await _auth.signOut();
        throw EmailNotVerifiedException();
      }
      final user = await _profileFromFirebase(refreshed);
      if (user.isVet) {
        await VetRepository(firestore: _firestore).ensureDirectoryListing(user);
      }
      await _session.signIn(user, remember: remember);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Connexion impossible. Vérifie Firebase.');
    }
  }

  Future<void> register({
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
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name.trim());

      final userData = <String, dynamic>{
        'username': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role == UserRole.vet) {
        final vetServices = services.isEmpty
            ? <String>['Consultation', 'Vaccination']
            : services;
        final clinicName =
            clinic.trim().isEmpty ? 'Cabinet privé' : clinic.trim();
        final vetAddress = address.trim().isEmpty
            ? (phone.trim().isEmpty
                ? 'Coordonnées via l’app'
                : 'Tél. ${phone.trim()}')
            : address.trim();

        userData.addAll({
          'specialty': specialty.trim(),
          'clinic': clinicName,
          'address': vetAddress,
          'services': vetServices,
          'hoursWeekdays': hoursWeekdays.trim(),
          'hoursSaturday': hoursSaturday.trim(),
        });

        await _firestore.collection('users').doc(fbUser.uid).set(userData);
        await _firestore.collection('vets').doc(fbUser.uid).set({
          'name': name.trim(),
          'specialty': specialty.trim(),
          'clinic': clinicName,
          'address': vetAddress,
          'services': vetServices,
          'hoursWeekdays': hoursWeekdays.trim(),
          'hoursSaturday': hoursSaturday.trim(),
          'phone': phone.trim(),
          'rating': 5.0,
          'reviews': 0,
          'distance': '—',
          'experience': 1,
          'availableToday': true,
          'colorHex': 0xFF4C7CF6,
          'price': 'Sur devis',
          'image': '',
          'email': email.trim().toLowerCase(),
          'userId': fbUser.uid,
        });
      } else {
        await _firestore.collection('users').doc(fbUser.uid).set(userData);
      }

      await fbUser.sendEmailVerification();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Inscription impossible. Vérifie Firebase.');
    }
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw AppException('Impossible de renvoyer le mail.');
      }
      await user.reload();
      if (user.emailVerified) {
        await _auth.signOut();
        throw AppException('E-mail déjà confirmé. Tu peux te connecter.');
      }
      await user.sendEmailVerification();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Envoi du mail impossible.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _session.signOut();
  }

  Future<AppUser> _profileFromFirebase(User fbUser) async {
    final doc = await _firestore.collection('users').doc(fbUser.uid).get();
    final data = doc.data();
    return AppUser(
      id: fbUser.uid,
      name: (data?['username'] ?? fbUser.displayName ?? 'Utilisateur')
          .toString(),
      email: (data?['email'] ?? fbUser.email ?? '').toString(),
      phone: (data?['phone'] ?? '').toString(),
      role: data?['role']?.toString() == 'vet' ? UserRole.vet : UserRole.owner,
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte est désactivé.';
      case 'user-not-found':
        return 'Aucun compte pour cet e-mail. Inscris-toi d’abord.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet e-mail est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min.).';
      case 'network-request-failed':
        return 'Pas de réseau. Vérifie ta connexion.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      default:
        return e.message ?? 'Erreur d’authentification (${e.code}).';
    }
  }
}
