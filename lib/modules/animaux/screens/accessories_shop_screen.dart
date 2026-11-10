import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/animaux/repositories/accessory_repository.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/animaux/screens/accessory_form_screen.dart';

class AccessoriesShopScreen extends StatefulWidget {
  const AccessoriesShopScreen({super.key});

  @override
  State<AccessoriesShopScreen> createState() => _AccessoriesShopScreenState();
}

class _AccessoriesShopScreenState extends State<AccessoriesShopScreen> {
  static const _speciesFilters = ['Tous', 'Chien', 'Chat', 'Lapin'];

  final _repo = AccessoryRepository();
  String _species = 'Tous';
  List<Accessory> _items = [];
  List<CartItem> _cart = [];
  bool _loading = true;

  String? get _ownerId => Session.instance.userId;
  bool get _isAdmin => Session.instance.currentUser?.isAdmin == true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _denyAdminOnly() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réservé à l’administrateur'),
      ),
    );
  }

  Future<void> _reload() async {
    final ownerId = _ownerId;
    if (ownerId == null) return;
    setState(() => _loading = true);
    final items = await _repo.getAll(species: _species);
    final cart = await _repo.getCart(ownerId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _cart = cart;
      _loading = false;
    });
  }

  Future<void> _openForm({Accessory? accessory}) async {
    if (!_isAdmin) {
      _denyAdminOnly();
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccessoryFormScreen(accessory: accessory),
      ),
    );
    if (ok == true) await _reload();
  }

  Future<void> _addToCart(Accessory a) async {
    final ownerId = _ownerId;
    if (ownerId == null || a.id == null) return;
    if (a.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rupture de stock')),
      );
      return;
    }
    await _repo.addToCart(ownerId: ownerId, accessoryId: a.id!);
    await _reload();
    if (!mounted) return;
    showSuccessSnack(context, '${a.name} ajouté au panier');
  }

  Future<void> _checkout() async {
    final ownerId = _ownerId;
    if (ownerId == null || _cart.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Confirmer l’achat ?',
      message:
          'Total : ${_cart.fold<double>(0, (s, i) => s + i.lineTotal).toStringAsFixed(0)} DT\nLe stock sera mis à jour localement.',
      confirmLabel: 'Acheter',
    );
    if (!ok) return;
    await _repo.checkout(ownerId);
    await _reload();
    if (!mounted) return;
    showSuccessSnack(context, 'Achat enregistré');
  }

  @override
  Widget build(BuildContext context) {
    final cartQty = _cart.fold<int>(0, (s, i) => s + i.quantity);
    final total = _cart.fold<double>(0, (s, i) => s + i.lineTotal);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accessoires'),
          actions: [
            if (_isAdmin)
              IconButton(
                tooltip: 'Ajouter un produit (admin)',
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_business_rounded),
              ),
          ],
          bottom: _isAdmin
              ? null
              : TabBar(
                  tabs: [
                    const Tab(text: 'Boutique'),
                    Tab(text: cartQty > 0 ? 'Panier ($cartQty)' : 'Panier'),
                  ],
                ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _isAdmin
                ? _shopTab()
                : TabBarView(
                    children: [
                      _shopTab(),
                      _cartTab(total),
                    ],
                  ),
      ),
    );
  }

  Widget _shopTab() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _speciesFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = _speciesFilters[i];
              return ChoiceChip(
                label: Text(s),
                selected: _species == s,
                onSelected: (_) async {
                  setState(() => _species = s);
                  await _reload();
                },
              );
            },
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun accessoire',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final a = _items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(a.emoji,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  Text(
                                    '${a.category} · ${a.species}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        a.priceLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusPill(
                                        a.stock > 0
                                            ? 'Stock ${a.stock}'
                                            : 'Rupture',
                                        a.stock > 0
                                            ? AppColors.health
                                            : AppColors.reminder,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!_isAdmin)
                              IconButton(
                                tooltip: 'Ajouter au panier',
                                onPressed:
                                    a.stock > 0 ? () => _addToCart(a) : null,
                                icon: const Icon(
                                    Icons.add_shopping_cart_rounded),
                                color: AppColors.primary,
                              ),
                            if (_isAdmin)
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await _openForm(accessory: a);
                                  } else if (v == 'delete' && a.id != null) {
                                    final ok = await showConfirmDialog(
                                      context,
                                      title: 'Supprimer ${a.name} ?',
                                      message:
                                          'Retiré du catalogue et du panier.',
                                      confirmLabel: 'Supprimer',
                                    );
                                    if (!ok) return;
                                    await _repo.delete(a.id!);
                                    await _reload();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _cartTab(double total) {
    if (_cart.isEmpty) {
      return const Center(
        child: Text(
          'Panier vide',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _cart.length,
            itemBuilder: (context, i) {
              final item = _cart[i];
              final a = item.accessory;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    children: [
                      Text(a?.emoji ?? '🛍️',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a?.name ?? 'Produit',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              '${a?.priceLabel ?? '—'} × ${item.quantity}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: item.id == null
                            ? null
                            : () async {
                                await _repo.updateCartQuantity(
                                    item.id!, item.quantity - 1);
                                await _reload();
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: item.id == null
                            ? null
                            : () async {
                                await _repo.updateCartQuantity(
                                    item.id!, item.quantity + 1);
                                await _reload();
                              },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        onPressed: item.id == null
                            ? null
                            : () async {
                                await _repo.removeFromCart(item.id!);
                                await _reload();
                              },
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.reminder),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppCard(
              color: AppColors.primaryLight,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _checkout,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Acheter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
