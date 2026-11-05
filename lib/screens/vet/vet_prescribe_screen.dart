import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../repositories/food_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class VetPrescribeScreen extends StatefulWidget {
  final String ownerId;
  final int localPetId;
  final String petName;
  final String petEmoji;

  const VetPrescribeScreen({
    super.key,
    required this.ownerId,
    required this.localPetId,
    required this.petName,
    required this.petEmoji,
  });

  @override
  State<VetPrescribeScreen> createState() => _VetPrescribeScreenState();
}

class _VetPrescribeScreenState extends State<VetPrescribeScreen> {
  final _food = FoodRepository();
  final _type = TextEditingController();
  final _goal = TextEditingController();
  final _notes = TextEditingController();
  double _meals = 3;
  final List<FoodItem> _items = [];
  bool _loading = true;
  bool _saving = false;

  List<FoodItem> get _allowed =>
      _items.where((e) => e.allowed).toList(growable: false);
  List<FoodItem> get _forbidden =>
      _items.where((e) => !e.allowed).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _type.dispose();
    _goal.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final diet = await _food.getDiet(
      ownerId: widget.ownerId,
      petId: widget.localPetId,
    );
    final allowed = await _food.getFoodItems(
      ownerId: widget.ownerId,
      petId: widget.localPetId,
      allowed: true,
    );
    final forbidden = await _food.getFoodItems(
      ownerId: widget.ownerId,
      petId: widget.localPetId,
      allowed: false,
    );
    if (!mounted) return;
    if (diet != null) {
      _type.text = diet.dietType;
      _goal.text = diet.goal;
      _notes.text = diet.notes;
      _meals = diet.mealsPerDay.toDouble();
    }
    setState(() {
      _items
        ..clear()
        ..addAll(allowed)
        ..addAll(forbidden);
      _loading = false;
    });
  }

  Future<void> _addItem({required bool allowed}) async {
    final result = await showModalBottomSheet<_FoodDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _AddFoodSheet(allowed: allowed),
    );
    if (result == null || result.name.isEmpty) return;
    setState(() {
      _items.add(FoodItem(
        petId: widget.localPetId,
        name: result.name,
        emoji: result.emoji,
        note: result.note,
        allowed: allowed,
      ));
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _food.upsertDiet(
        ownerId: widget.ownerId,
        diet: Diet(
          petId: widget.localPetId,
          dietType: _type.text.trim(),
          goal: _goal.text.trim(),
          mealsPerDay: _meals.round(),
          notes: _notes.text.trim(),
        ),
      );
      await _food.replaceFoodItems(
        ownerId: widget.ownerId,
        petId: widget.localPetId,
        items: _items,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'Prescription enregistrée');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec enregistrement Firestore')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('${widget.petEmoji} ${widget.petName}'),
        backgroundColor: AppColors.background,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.vet,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _saving ? 'Enregistrement…' : 'Enregistrer la prescription',
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            color: const Color(0xFFEEF3FF),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.petEmoji,
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.petName, style: text.titleMedium),
                      const SizedBox(height: 2),
                      const Text(
                        'Prescription alimentaire',
                        style: TextStyle(
                          color: AppColors.vet,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Régime', style: text.titleMedium),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(
                  label: 'Type de régime',
                  hint: 'Croquettes hypoallergéniques',
                  icon: Icons.restaurant_menu_rounded,
                  controller: _type,
                ),
                LabeledField(
                  label: 'Objectif',
                  hint: 'Perte de poids / maintien…',
                  icon: Icons.flag_outlined,
                  controller: _goal,
                ),
                Text(
                  'Repas / jour : ${_meals.round()}',
                  style: text.titleMedium,
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.vet,
                    thumbColor: AppColors.vet,
                    overlayColor: AppColors.vet.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _meals,
                    min: 1,
                    max: 6,
                    divisions: 5,
                    label: '${_meals.round()}',
                    onChanged: (v) => setState(() => _meals = v),
                  ),
                ),
                LabeledField(
                  label: 'Notes vétérinaires',
                  hint: 'Consignes pour le propriétaire',
                  controller: _notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Aliments', style: text.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  color: AppColors.health,
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Autorisé',
                  onTap: () => _addItem(allowed: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  color: AppColors.reminder,
                  icon: Icons.block_rounded,
                  label: 'Interdit',
                  onTap: () => _addItem(allowed: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FoodSection(
            title: 'Autorisés (${_allowed.length})',
            color: AppColors.health,
            items: _allowed,
            emptyText: 'Aucun aliment autorisé pour l’instant',
            onRemove: (item) => setState(() => _items.remove(item)),
          ),
          const SizedBox(height: 12),
          _FoodSection(
            title: 'Interdits (${_forbidden.length})',
            color: AppColors.reminder,
            items: _forbidden,
            emptyText: 'Aucun aliment interdit pour l’instant',
            onRemove: (item) => setState(() => _items.remove(item)),
          ),
        ],
      ),
    );
  }
}

class _FoodDraft {
  final String name;
  final String emoji;
  final String note;

  const _FoodDraft({
    required this.name,
    required this.emoji,
    required this.note,
  });
}

class _AddFoodSheet extends StatefulWidget {
  final bool allowed;

  const _AddFoodSheet({required this.allowed});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late final TextEditingController _name;
  late final TextEditingController _emoji;
  late final TextEditingController _note;
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _emoji = TextEditingController(text: widget.allowed ? '🍗' : '🍫');
    _note = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _emoji.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un nom d’aliment')),
      );
      return;
    }
    Navigator.pop(
      context,
      _FoodDraft(
        name: name,
        emoji: _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.allowed;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: allowed ? AppColors.health : AppColors.reminder,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allowed ? 'Aliment autorisé' : 'Aliment interdit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              enableSuggestions: true,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Poulet, riz…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emoji,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: '🍗',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Portion, fréquence…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          allowed ? AppColors.health : AppColors.reminder,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _submit,
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<FoodItem> items;
  final String emptyText;
  final ValueChanged<FoodItem> onRemove;

  const _FoodSection({
    required this.title,
    required this.color,
    required this.items,
    required this.emptyText,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyText,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.note,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retirer',
                        onPressed: () => onRemove(item),
                        icon: Icon(Icons.close_rounded,
                            color: color.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
