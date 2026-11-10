import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/animaux/repositories/accessory_repository.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';

class AccessoryFormScreen extends StatefulWidget {
  final Accessory? accessory;

  const AccessoryFormScreen({super.key, this.accessory});

  @override
  State<AccessoryFormScreen> createState() => _AccessoryFormScreenState();
}

class _AccessoryFormScreenState extends State<AccessoryFormScreen> {
  static const _categories = [
    'Promenade',
    'Maison',
    'Jouets',
    'Toilettage',
    'Repas',
    'Santé',
  ];
  static const _species = ['Tous', 'Chien', 'Chat', 'Lapin'];

  final _formKey = GlobalKey<FormState>();
  final _repo = AccessoryRepository();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _emoji;
  late final TextEditingController _stock;
  late String _category;
  late String _speciesValue;
  bool _saving = false;

  bool get _editing => widget.accessory != null;

  @override
  void initState() {
    super.initState();
    final a = widget.accessory;
    _name = TextEditingController(text: a?.name ?? '');
    _price = TextEditingController(
        text: a == null ? '' : a.price.toStringAsFixed(0));
    _description = TextEditingController(text: a?.description ?? '');
    _emoji = TextEditingController(text: a?.emoji ?? '🛍️');
    _stock = TextEditingController(text: '${a?.stock ?? 10}');
    _category = a?.category ?? _categories.first;
    _speciesValue = a?.species ?? 'Tous';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Session.instance.currentUser?.isAdmin != true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservé à l’administrateur')),
        );
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _emoji.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (Session.instance.currentUser?.isAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservé à l’administrateur')),
      );
      return;
    }
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final item = Accessory(
      id: widget.accessory?.id,
      name: _name.text.trim(),
      category: _category,
      species: _speciesValue,
      price: price,
      description: _description.text.trim(),
      emoji: _emoji.text.trim().isEmpty ? '🛍️' : _emoji.text.trim(),
      stock: stock.clamp(0, 9999),
    );
    if (_editing) {
      await _repo.update(item);
    } else {
      await _repo.insert(item);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    showSuccessSnack(
      context,
      _editing ? 'Accessoire modifié' : 'Accessoire ajouté',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier l’accessoire' : 'Nouvel accessoire'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            LabeledField(
              label: 'Nom',
              hint: 'Ex. Laisse rétractable',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            LabeledField(
              label: 'Prix (DT)',
              hint: '25',
              controller: _price,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n < 0) return 'Prix invalide';
                return null;
              },
            ),
            LabeledField(
              label: 'Stock',
              hint: '10',
              controller: _stock,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Stock invalide';
                return null;
              },
            ),
            LabeledField(
              label: 'Emoji',
              hint: '🦮',
              controller: _emoji,
            ),
            const Text(
              'Catégorie',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Espèce',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _species)
                  ChoiceChip(
                    label: Text(s),
                    selected: _speciesValue == s,
                    onSelected: (_) => setState(() => _speciesValue = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Description',
              hint: 'Détails…',
              controller: _description,
              maxLines: 3,
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_editing ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
