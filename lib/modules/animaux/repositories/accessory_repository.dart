import 'package:sqflite/sqflite.dart';

import 'package:flutter_example/core/data/app_database.dart';
import 'package:flutter_example/core/models/models.dart';

class AccessoryRepository {
  final _db = AppDatabase.instance;

  Future<List<Accessory>> getAll({String? species, String? category}) async {
    await _ensureSeeded();
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (species != null && species != 'Tous') {
      where.add('(species = ? OR species = ?)');
      args.addAll([species, 'Tous']);
    }
    if (category != null && category != 'Tous') {
      where.add('category = ?');
      args.add(category);
    }
    final rows = await db.query(
      'accessories',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(Accessory.fromMap).toList();
  }

  Future<Accessory?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'accessories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Accessory.fromMap(rows.first);
  }

  Future<int> insert(Accessory a) async {
    final db = await _db.database;
    return db.insert('accessories', a.toMap()..remove('id'));
  }

  Future<void> update(Accessory a) async {
    if (a.id == null) return;
    final db = await _db.database;
    await db.update(
      'accessories',
      a.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('cart_items', where: 'accessory_id = ?', whereArgs: [id]);
    await db.delete('accessories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CartItem>> getCart(String ownerId) async {
    await _ensureSeeded();
    final db = await _db.database;
    final rows = await db.query(
      'cart_items',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'id DESC',
    );
    final items = <CartItem>[];
    for (final row in rows) {
      final accId = row['accessory_id'] as int;
      final accessory = await getById(accId);
      items.add(CartItem.fromMap(row, accessory: accessory));
    }
    return items;
  }

  Future<int> cartCount(String ownerId) async {
    final items = await getCart(ownerId);
    return items.fold<int>(0, (s, i) => s + i.quantity);
  }

  Future<double> cartTotal(String ownerId) async {
    final items = await getCart(ownerId);
    return items.fold<double>(0, (s, i) => s + i.lineTotal);
  }

  Future<void> addToCart({
    required String ownerId,
    required int accessoryId,
    int quantity = 1,
  }) async {
    final db = await _db.database;
    final existing = await db.query(
      'cart_items',
      where: 'owner_id = ? AND accessory_id = ?',
      whereArgs: [ownerId, accessoryId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('cart_items', {
        'owner_id': ownerId,
        'accessory_id': accessoryId,
        'quantity': quantity.clamp(1, 99),
      });
      return;
    }
    final current = (existing.first['quantity'] as int?) ?? 1;
    await db.update(
      'cart_items',
      {'quantity': (current + quantity).clamp(1, 99)},
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  Future<void> updateCartQuantity(int cartItemId, int quantity) async {
    final db = await _db.database;
    if (quantity <= 0) {
      await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
      return;
    }
    await db.update(
      'cart_items',
      {'quantity': quantity.clamp(1, 99)},
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> removeFromCart(int cartItemId) async {
    final db = await _db.database;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  Future<void> clearCart(String ownerId) async {
    final db = await _db.database;
    await db.delete('cart_items', where: 'owner_id = ?', whereArgs: [ownerId]);
  }

  /// « Achat » local : décrémente le stock et vide le panier.
  Future<void> checkout(String ownerId) async {
    final items = await getCart(ownerId);
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final item in items) {
        final acc = item.accessory;
        if (acc?.id == null) continue;
        final nextStock = (acc!.stock - item.quantity).clamp(0, 9999);
        await txn.update(
          'accessories',
          {'stock': nextStock},
          where: 'id = ?',
          whereArgs: [acc.id],
        );
      }
      await txn.delete(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
    });
  }

  Future<void> _ensureSeeded() async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM accessories'),
        ) ??
        0;
    if (count > 0) return;
    const seeds = <Accessory>[
      Accessory(
        name: 'Laisse rétractable',
        category: 'Promenade',
        species: 'Chien',
        price: 45,
        description: 'Laisse 5 m, frein sécurisé.',
        emoji: '🦮',
        stock: 12,
      ),
      Accessory(
        name: 'Collier anti-puces',
        category: 'Santé',
        species: 'Chien',
        price: 28,
        description: 'Protection 6 mois.',
        emoji: '📿',
        stock: 20,
      ),
      Accessory(
        name: 'Arbre à chat',
        category: 'Maison',
        species: 'Chat',
        price: 120,
        description: '2 plateformes + griffoir.',
        emoji: '🌳',
        stock: 5,
      ),
      Accessory(
        name: 'Jouet souris',
        category: 'Jouets',
        species: 'Chat',
        price: 12,
        description: 'Peluche avec herbe à chat.',
        emoji: '🐭',
        stock: 30,
      ),
      Accessory(
        name: 'Cage confort',
        category: 'Maison',
        species: 'Lapin',
        price: 95,
        description: 'Cage XL avec bac amovible.',
        emoji: '🏠',
        stock: 4,
      ),
      Accessory(
        name: 'Brosse démêlante',
        category: 'Toilettage',
        species: 'Tous',
        price: 18,
        description: 'Pour poils longs et courts.',
        emoji: '🪥',
        stock: 25,
      ),
      Accessory(
        name: 'Gamelle inox',
        category: 'Repas',
        species: 'Tous',
        price: 22,
        description: 'Double gamelle antidérapante.',
        emoji: '🥣',
        stock: 18,
      ),
      Accessory(
        name: 'Panier douillet',
        category: 'Maison',
        species: 'Tous',
        price: 65,
        description: 'Coussin lavable, taille M.',
        emoji: '🛏️',
        stock: 9,
      ),
    ];
    for (final a in seeds) {
      await db.insert('accessories', a.toMap()..remove('id'));
    }
  }
}
