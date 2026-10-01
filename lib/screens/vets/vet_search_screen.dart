import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
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
    'Urgences 24h/24',
  ];
  String _filter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final vets = _filter == 'Tous'
        ? MockData.vets
        : MockData.vets.where((v) => v.specialty == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un vétérinaire')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nom, clinique, ville…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_filters[i]),
                selected: _filter == _filters[i],
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = _filters[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  for (final (x, y) in const [
                    (0.2, 0.3),
                    (0.55, 0.6),
                    (0.8, 0.25),
                    (0.35, 0.75)
                  ])
                    Align(
                      alignment: Alignment(x * 2 - 1, y * 2 - 1),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.vet, size: 32),
                    ),
                  const Align(
                    alignment: Alignment(0, 0),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: CircleAvatar(
                          radius: 4, backgroundColor: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded,
                              size: 18, color: AppColors.vet),
                          SizedBox(width: 6),
                          Text('Voir la carte',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader('${vets.length} vétérinaires à proximité'),
          ),
          for (final vet in vets)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: VetCard(vet: vet),
            ),
        ],
      ),
    );
  }
}

class VetCard extends StatelessWidget {
  final Vet vet;

  const VetCard({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VetProfileScreen(vet: vet)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VetAvatar(vet, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vet.name, style: Theme.of(context).textTheme.titleMedium),
                Text('${vet.specialty} · ${vet.clinic}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.food, size: 18),
                        Text(' ${vet.rating}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy)),
                        Text(' (${vet.reviews})',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.textSecondary, size: 16),
                        Text(vet.distance,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                vet.availableToday
                    ? const StatusPill('Disponible aujourd\'hui',
                        AppColors.health,
                        icon: Icons.bolt_rounded)
                    : const StatusPill(
                        'Prochaine dispo : demain', AppColors.textSecondary,
                        icon: Icons.schedule_rounded),
              ],
            ),
          ),
          const Icon(Icons.favorite_border_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
