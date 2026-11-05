import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../repositories/vet_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'vet_profile_screen.dart';

class VetSearchScreen extends StatefulWidget {
  const VetSearchScreen({super.key});

  @override
  State<VetSearchScreen> createState() => _VetSearchScreenState();
}

class _VetSearchScreenState extends State<VetSearchScreen> {
  static const _filters = [
    'Tous',
    'Généraliste',
    'Chirurgie',
    'NAC',
    'Dentaire',
  ];

  final _repo = VetRepository();
  String _filter = 'Tous';
  late Future<List<Vet>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getVets(specialty: _filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un vétérinaire')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                return ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() {
                    _filter = f;
                    _reload();
                  }),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Vet>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Erreur : ${snap.error}'));
                }
                final vets = snap.data ?? [];
                if (vets.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun vétérinaire.\nDémarre le backend (npm run dev) puis réessaie.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: vets.length,
                  itemBuilder: (context, i) {
                    final v = vets[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VetProfileScreen(vet: v)),
                        ),
                        child: Row(
                          children: [
                            VetAvatar(v, size: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy)),
                                  Text('${v.specialty} · ${v.clinic}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16, color: AppColors.food),
                                      Text(' ${v.rating} (${v.reviews})',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 10),
                                      Text(v.distance,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  StatusPill(
                                    v.availableToday
                                        ? "Disponible aujourd'hui"
                                        : 'Prochaine dispo : demain',
                                    v.availableToday
                                        ? AppColors.health
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
