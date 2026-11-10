import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/vet_repository.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/screens/profile/edit_profile_screen.dart';
import 'package:flutter_example/modules/compte/screens/vets/vet_profile_screen.dart';

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
  late Future<_SearchResult> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_SearchResult> _load() async {
    final user = Session.instance.currentUser;
    double? lat = user?.latitude;
    double? lon = user?.longitude;

    // Si l'adresse est en GPS texte mais lat/lon absents → parser / géocoder.
    if ((lat == null || lon == null) &&
        user != null &&
        user.address.trim().isNotEmpty) {
      try {
        final point =
            await GeocodingService().geocodeAddress(user.address.trim());
        lat = point.latitude;
        lon = point.longitude;
        await Session.instance.updateLocalProfile(
          user.copyWith(latitude: lat, longitude: lon),
        );
      } catch (_) {}
    }

    if (lat != null && lon != null) {
      final nearby = await _repo.getNearbyCombined(
        latitude: lat,
        longitude: lon,
        specialty: _filter,
      );
      return _SearchResult(
        vets: nearby.vets,
        usedLocation: true,
        osmCount: nearby.osmCount,
        source: nearby.source,
        warning: nearby.warning,
        addressLabel: user?.address.isNotEmpty == true
            ? user!.address
            : '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
      );
    }

    final local = await _repo.getVets(specialty: _filter);
    return _SearchResult(
      vets: local,
      usedLocation: false,
      osmCount: 0,
      source: 'SQLite local',
      warning: 'Adresse / GPS manquant → OpenStreetMap non interrogé',
      addressLabel: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un vétérinaire'),
        actions: [
          IconButton(
            tooltip: 'Actualiser (OSM)',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
            child: FutureBuilder<_SearchResult>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Recherche OpenStreetMap…',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Overpass puis Nominatim (peut prendre 10–20 s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(child: Text('Erreur : ${snap.error}'));
                }
                final result = snap.data!;
                final vets = result.vets;
                final extra = vets.isEmpty ? 1 : 0;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: vets.length + 1 + extra,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NearbyBanner(
                          result: result,
                          onSetAddress: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                            if (mounted) setState(_reload);
                          },
                          onRetry: () => setState(_reload),
                        ),
                      );
                    }
                    if (vets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'Aucun cabinet trouvé.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    final v = vets[i - 1];
                    final isOsm = v.id.startsWith('osm_');
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ),
                                      StatusPill(
                                        isOsm ? 'OSM' : 'Local',
                                        isOsm
                                            ? AppColors.vet
                                            : AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${v.specialty} · ${v.clinic}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me_rounded,
                                          size: 14, color: AppColors.primary),
                                      Text(
                                        ' ${v.distance}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (!isOsm) ...[
                                        const SizedBox(width: 10),
                                        const Icon(Icons.star_rounded,
                                            size: 16, color: AppColors.food),
                                        Text(
                                          ' ${v.rating}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (v.address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      v.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
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

class _SearchResult {
  final List<Vet> vets;
  final bool usedLocation;
  final int osmCount;
  final String source;
  final String? warning;
  final String? addressLabel;

  const _SearchResult({
    required this.vets,
    required this.usedLocation,
    required this.osmCount,
    required this.source,
    required this.warning,
    required this.addressLabel,
  });
}

class _NearbyBanner extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onSetAddress;
  final VoidCallback onRetry;

  const _NearbyBanner({
    required this.result,
    required this.onSetAddress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!result.usedLocation) {
      return AppCard(
        color: AppColors.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajoute une adresse ou des GPS (ex. 36,6833, 10,3007) pour charger les vrais cabinets OpenStreetMap.',
              style: TextStyle(color: AppColors.navy, height: 1.35),
            ),
            TextButton.icon(
              onPressed: onSetAddress,
              icon: const Icon(Icons.place_outlined, size: 18),
              label: const Text('Renseigner mon adresse'),
            ),
          ],
        ),
      );
    }

    final ok = result.osmCount > 0;
    return AppCard(
      color: ok ? const Color(0xFFEEF3FF) : const Color(0xFFFFF4E5),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.map_outlined : Icons.warning_amber_rounded,
                color: ok ? AppColors.vet : AppColors.food,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok
                      ? '${result.osmCount} cabinet(s) OSM · ${result.source}'
                      : result.source,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Réessayer OSM',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          if (result.addressLabel != null)
            Text(
              result.addressLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          if (result.warning != null) ...[
            const SizedBox(height: 6),
            Text(
              result.warning!,
              style: TextStyle(
                fontSize: 12,
                color: ok ? AppColors.textSecondary : AppColors.food,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
