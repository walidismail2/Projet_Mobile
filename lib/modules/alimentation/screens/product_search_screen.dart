import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/services/food_safety_service.dart';
import 'package:flutter_example/modules/alimentation/services/pet_food_api_service.dart';

/// Recherche d'un aliment du commerce dans Open Pet Food Facts.
/// Renvoie le [PetFoodProduct] choisi via `Navigator.pop`.
class ProductSearchScreen extends StatefulWidget {
  final Pet pet;
  final List<FoodItem> vetItems;
  final String initialQuery;

  const ProductSearchScreen({
    super.key,
    required this.pet,
    this.vetItems = const [],
    this.initialQuery = '',
  });

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _api = PetFoodApiService();
  late final TextEditingController _query;
  Timer? _debounce;
  List<PetFoodProduct> _results = [];
  bool _loading = false;
  bool _fromCache = false;
  bool _speciesOnly = true;
  int _requestId = 0;

  String? get _species =>
      _speciesOnly ? PetFoodApiService.speciesTag(widget.pet.species) : null;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 3) _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    // L'API limite les recherches : on attend la fin de la frappe.
    _debounce = Timer(const Duration(milliseconds: 600), _run);
  }

  Future<void> _run() async {
    final q = _query.text.trim();
    if (q.length < 3) {
      setState(() {
        _results = [];
        _fromCache = false;
      });
      return;
    }
    final id = ++_requestId;
    setState(() => _loading = true);
    final r = await _api.search(q, species: _species);
    if (!mounted || id != _requestId) return;
    setState(() {
      _results = r.products;
      _fromCache = r.fromCache;
      _loading = false;
    });
  }

  Future<void> _open(PetFoodProduct p) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ProductDetailSheet(
        product: p,
        pet: widget.pet,
        vetItems: widget.vetItems,
      ),
    );
    if (chosen == true && mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final speciesLabel = widget.pet.species == 'Chat' ? 'chats' : 'chiens';
    final canFilter = PetFoodApiService.speciesTag(widget.pet.species) != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Chercher un aliment')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _query,
              autofocus: widget.initialQuery.isEmpty,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _run(),
              decoration: InputDecoration(
                hintText: 'Marque, produit ou code-barres',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (canFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Pour $speciesLabel uniquement'),
                    selected: _speciesOnly,
                    onSelected: (v) {
                      setState(() => _speciesOnly = v);
                      _run();
                    },
                  ),
                ],
              ),
            ),
          if (_fromCache)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hors ligne · résultats tirés des produits déjà vus',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _body()),
          _Attribution(),
        ],
      ),
    );
  }

  Widget _body() {
    final q = _query.text.trim();
    if (q.length < 3) {
      return const _Hint(
        icon: Icons.manage_search_rounded,
        text:
            'Tape au moins 3 lettres (ex. « Royal Canin », « croquettes '
            'saumon ») ou le code-barres du paquet.',
      );
    }
    if (!_loading && _results.isEmpty) {
      return _Hint(
        icon: Icons.search_off_rounded,
        text: _fromCache
            ? 'Aucun produit en cache pour « $q ».'
            : 'Aucun produit trouvé pour « $q ».'
                  '${_speciesOnly ? ' Essaie sans le filtre espèce.' : ''}',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _results[i];
        return AppCard(
          padding: const EdgeInsets.all(10),
          onTap: () => _open(p),
          child: Row(
            children: [
              ProductThumb(url: p.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        p.brand,
                        p.quantity,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(kcalLabel(p), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }
}

String kcalLabel(PetFoodProduct p) => p.kcalPer100g == null
    ? 'kcal non renseignées'
    : '${p.kcalPer100g!.round()} kcal / 100 g'
          '${p.kcalEstimated ? ' (estimé)' : ''}';

/// Fiche produit : kcal, ingrédients, alertes. Pop `true` = « Utiliser ».
class ProductDetailSheet extends StatelessWidget {
  final PetFoodProduct product;
  final Pet pet;
  final List<FoodItem> vetItems;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.pet,
    required this.vetItems,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final alerts = FoodSafetyService.checkText(
      '${p.name} ${p.ingredients}',
      species: pet.species,
      vetItems: vetItems,
      includeCaution: false,
    );
    final wrongSpecies =
        (p.species == 'dog' && pet.species == 'Chat') ||
        (p.species == 'cat' && pet.species == 'Chien');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              ProductThumb(url: p.imageUrl, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        p.brand,
                        p.quantity,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Code-barres ${p.code}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoRow(
            Icons.local_fire_department_outlined,
            'Énergie',
            kcalLabel(p),
          ),
          if (p.kcalEstimated)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Estimé depuis l’analyse (protéines, matières grasses, '
                'cellulose, cendres, humidité) — vérifie sur l’étiquette.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          if (wrongSpecies)
            _AlertTile(
              icon: '⚠️',
              title: p.species == 'dog'
                  ? 'Produit pour chiens'
                  : 'Produit pour chats',
              text: pet.species == 'Chat'
                  ? 'Les aliments pour chiens ne couvrent pas les besoins du '
                        'chat (taurine notamment).'
                  : 'Les aliments pour chats sont trop riches pour un chien.',
            ),
          for (final a in alerts)
            _AlertTile(
              icon: a.level.icon,
              title: '${a.level.label} : ${a.title}',
              text: a.reason,
            ),
          if (alerts.isEmpty && p.ingredients.isNotEmpty && !wrongSpecies)
            const _AlertTile(
              icon: '✅',
              title: 'Aucun ingrédient à risque détecté',
              text: 'Comparé à la base PetCare et aux interdits du véto.',
            ),
          const SizedBox(height: 8),
          Text('Ingrédients', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            p.ingredients.isEmpty ? 'Non renseignés.' : p.ingredients,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Utiliser ce produit'),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String icon;
  final String title;
  final String text;

  const _AlertTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(text, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductThumb extends StatelessWidget {
  final String url;
  final double size;

  const ProductThumb({super.key, required this.url, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.background,
      child: const Icon(Icons.pets_rounded, color: AppColors.textSecondary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: TextButton(
        onPressed: () => launchUrl(
          Uri.https(PetFoodApiService.host),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text(
          'Données : Open Pet Food Facts (ODbL)',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
