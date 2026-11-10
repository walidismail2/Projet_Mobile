import 'package:flutter/material.dart';

import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/animaux/repositories/pet_repository.dart';
import 'package:flutter_example/modules/compte/screens/vet_role/vet_prescribe_screen.dart';

class VetPatientsScreen extends StatefulWidget {
  const VetPatientsScreen({super.key});

  @override
  State<VetPatientsScreen> createState() => _VetPatientsScreenState();
}

class _VetPatientsScreenState extends State<VetPatientsScreen> {
  final _email = TextEditingController();
  final _repo = PetRepository();
  List<Map<String, dynamic>> _pets = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Entre l’e-mail du propriétaire';
        _searched = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _pets = [];
      _searched = true;
    });
    try {
      final pets = await _repo.findPetsByOwnerEmail(email);
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _loading = false;
        if (pets.isEmpty) {
          _error =
              'Aucun animal trouvé. Le propriétaire doit d’abord ajouter un animal (même appareil / SQLite).';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Recherche impossible.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4C7CF6), Color(0xFF6B9BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.vet.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_liquid_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Prescrire un régime',
                      style: text.titleLarge!.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Retrouve un propriétaire par e-mail, choisis un animal, puis définis le régime et les aliments autorisés / interdits.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recherche patient', style: text.titleMedium),
              const SizedBox(height: 12),
              LabeledField(
                label: 'E-mail du propriétaire',
                hint: 'client@email.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vet,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(_loading ? 'Recherche…' : 'Chercher les animaux'),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          AppCard(
            color: const Color(0xFFFFF0F2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.reminder),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: AppColors.reminder, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!_searched && _pets.isEmpty && _error == null) ...[
          const SizedBox(height: 28),
          const _EmptyHint(),
        ],
        if (_pets.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            '${_pets.length} animal${_pets.length > 1 ? 's' : ''} trouvé${_pets.length > 1 ? 's' : ''}',
            style: text.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final p in _pets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VetPrescribeScreen(
                        ownerId: p['ownerId']?.toString() ?? '',
                        localPetId: (p['localPetId'] as num).toInt(),
                        petName: p['name']?.toString() ?? 'Animal',
                        petEmoji: p['emoji']?.toString() ?? '🐾',
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.vet.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p['emoji']?.toString() ?? '🐾',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name']?.toString() ?? '',
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p['species'] ?? ''} · ${p['breed'] ?? ''}',
                            style: text.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Prescrire un régime →',
                            style: TextStyle(
                              color: AppColors.vet,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.vet),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.pets_rounded,
            size: 48, color: AppColors.vet.withValues(alpha: 0.35)),
        const SizedBox(height: 12),
        Text(
          'Commence par chercher un propriétaire',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Utilise l’e-mail du compte PetCare du client.',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
