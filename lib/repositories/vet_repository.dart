import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../data/vet_seed.dart';
import '../models/models.dart';

class VetRepository {
  final FirebaseFirestore _firestore;
  final AppDatabase _db = AppDatabase.instance;

  VetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vets =>
      _firestore.collection('vets');

  Future<List<Vet>> getVets({String? specialty}) async {
    try {
      await _ensureSeeded();
      final snap = await _vets.get();
      var vets =
          snap.docs.map((d) => Vet.fromFirestore(d.id, d.data())).toList();
      if (specialty != null && specialty != 'Tous') {
        vets = vets.where((v) => v.specialty == specialty).toList();
      }
      vets.sort((a, b) => b.rating.compareTo(a.rating));
      await _cacheAll(vets);
      return vets;
    } catch (_) {
      return _getCached(specialty: specialty);
    }
  }

  /// Publie / met à jour la fiche annuaire d'un compte véto connecté.
  Future<void> ensureDirectoryListing(AppUser user) async {
    if (!user.isVet) return;
    final userDoc =
        await _firestore.collection('users').doc(user.id).get();
    final u = userDoc.data() ?? {};
    final servicesRaw = u['services'];
    final services = servicesRaw is List
        ? servicesRaw.map((e) => e.toString()).toList()
        : <String>['Consultation', 'Vaccination'];

    final payload = <String, dynamic>{
      'name': user.name,
      'specialty': (u['specialty'] ?? 'Généraliste').toString(),
      'clinic': (u['clinic'] ?? 'Cabinet privé').toString(),
      'address': (u['address'] ??
              (user.phone.isEmpty
                  ? 'Coordonnées via l’app'
                  : 'Tél. ${user.phone}'))
          .toString(),
      'services': services,
      'hoursWeekdays': (u['hoursWeekdays'] ?? '08:30 – 19:00').toString(),
      'hoursSaturday': (u['hoursSaturday'] ?? '09:00 – 13:00').toString(),
      'phone': user.phone.isNotEmpty
          ? user.phone
          : (u['phone']?.toString() ?? ''),
      'email': user.email,
      'userId': user.id,
    };

    final existing = await _vets.doc(user.id).get();
    if (!existing.exists) {
      payload.addAll({
        'rating': 5.0,
        'reviews': 0,
        'distance': '—',
        'experience': 1,
        'availableToday': true,
        'colorHex': 0xFF4C7CF6,
        'price': 'Sur devis',
        'image': '',
      });
    }
    await _vets.doc(user.id).set(payload, SetOptions(merge: true));
  }

  Future<Vet?> getById(String id) async {
    try {
      final doc = await _vets.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return _getCachedById(id);
      }
      final vet = Vet.fromFirestore(doc.id, doc.data()!);
      final db = await _db.database;
      await db.insert(
        'vets_cache',
        vet.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return vet;
    } catch (_) {
      return _getCachedById(id);
    }
  }

  Future<void> _ensureSeeded() async {
    final existing = await _vets.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final v in kSeedVets) {
      batch.set(_vets.doc(v.id), v.toFirestoreMap());
    }
    await batch.commit();
  }

  Future<void> _cacheAll(List<Vet> vets) async {
    final db = await _db.database;
    final batch = db.batch();
    batch.delete('vets_cache');
    for (final v in vets) {
      batch.insert('vets_cache', v.toCacheMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Vet>> _getCached({String? specialty}) async {
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

  Future<Vet?> _getCachedById(String id) async {
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
}
