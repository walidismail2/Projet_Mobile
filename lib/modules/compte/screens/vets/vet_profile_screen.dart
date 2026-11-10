import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/modules/compte/repositories/vet_repository.dart';
import 'package:flutter_example/modules/compte/services/geocoding_service.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/screens/vets/booking_screen.dart';

class VetProfileScreen extends StatefulWidget {
  final Vet vet;

  const VetProfileScreen({super.key, required this.vet});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  late Vet _vet;
  final _geo = GeocodingService();
  final _repo = VetRepository();
  bool _geocoding = false;
  String? _geoError;
  String? _resolvedLabel;

  @override
  void initState() {
    super.initState();
    _vet = widget.vet;
  }

  Future<void> _geocode() async {
    setState(() {
      _geocoding = true;
      _geoError = null;
    });
    try {
      final point = await _geo.geocodeAddress(_vet.address);
      await _repo.updateCoordinates(
        vetId: _vet.id,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _vet = _vet.copyWith(
          latitude: point.latitude,
          longitude: point.longitude,
        );
        _resolvedLabel = point.displayName;
        _geocoding = false;
      });
      showSuccessSnack(context, 'Coordonnées enregistrées (SQLite)');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _geocoding = false;
        _geoError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openMaps() async {
    final lat = _vet.latitude;
    final lon = _vet.longitude;
    if (lat == null || lon == null) return;

    final label = Uri.encodeComponent(_vet.name);
    final candidates = <Uri>[
      // Intent geo natif Android (ouvre Maps / app carto par défaut)
      Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)'),
      Uri.parse('https://maps.google.com/?q=$lat,$lon'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon'),
      Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon'),
    ];

    for (final uri in candidates) {
      for (final mode in const [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
      ]) {
        try {
          final ok = await launchUrl(uri, mode: mode);
          if (ok) return;
        } catch (_) {
          // essaie le candidat / mode suivant
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Impossible d’ouvrir Maps. Installe Google Maps ou un navigateur.',
        ),
      ),
    );
  }

  Future<void> _copyCoords() async {
    final lat = _vet.latitude;
    final lon = _vet.longitude;
    if (lat == null || lon == null) return;
    await Clipboard.setData(ClipboardData(text: '$lat, $lon'));
    if (!mounted) return;
    showSuccessSnack(context, 'Coordonnées copiées');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vet = _vet;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil du vétérinaire'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation', style: text.bodyMedium),
                  Text(vet.price, style: text.titleLarge),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookingScreen(vet: vet)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Prendre rendez-vous'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(child: VetAvatar(vet, size: 110)),
          const SizedBox(height: 14),
          Center(child: Text(vet.name, style: text.headlineMedium)),
          const SizedBox(height: 4),
          Center(
            child: Text('Vétérinaire ${vet.specialty.toLowerCase()}',
                style: text.bodyMedium),
          ),
          const SizedBox(height: 10),
          Center(
            child: vet.availableToday
                ? const StatusPill('Disponible aujourd\'hui', AppColors.health,
                    icon: Icons.bolt_rounded)
                : const StatusPill('Prochaine dispo : demain', AppColors.food,
                    icon: Icons.schedule_rounded),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(
                  icon: Icons.people_alt_rounded,
                  color: AppColors.vet,
                  value: '1 200+',
                  label: 'Patients'),
              const SizedBox(width: 12),
              _Stat(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  value: '${vet.experience} ans',
                  label: 'Expérience'),
              const SizedBox(width: 12),
              _Stat(
                  icon: Icons.star_rounded,
                  color: AppColors.food,
                  value: '${vet.rating}',
                  label: '${vet.reviews} avis'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader('À propos'),
          Text(
            '${vet.name} exerce à la ${vet.clinic} depuis ${vet.experience} ans. '
            'Passionné(e) par le bien-être animal, il/elle accompagne chiens, chats '
            'et NAC avec douceur et pédagogie.',
            style: text.bodyMedium!.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Services'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in vet.services) _ServiceChip(s),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader('Adresse & horaires'),
          AppCard(
            child: Column(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: vet.hasCoordinates
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.my_location_rounded,
                                  color: AppColors.vet, size: 36),
                              const SizedBox(height: 6),
                              Text(
                                '${vet.latitude!.toStringAsFixed(5)}, ${vet.longitude!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.vet,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.location_on_rounded,
                            color: AppColors.vet, size: 40),
                  ),
                ),
                const SizedBox(height: 8),
                InfoRow(Icons.local_hospital_outlined, 'Clinique', vet.clinic),
                InfoRow(Icons.place_outlined, 'Adresse', vet.address),
                InfoRow(Icons.schedule_rounded, 'Lun – Ven', vet.hoursWeekdays),
                InfoRow(Icons.schedule_rounded, 'Samedi', vet.hoursSaturday),
                InfoRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  vet.phone.isEmpty ? 'Non renseigné' : vet.phone,
                ),
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.vet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nominatim · OpenStreetMap',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vet,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_geoError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _geoError!,
                      style: const TextStyle(color: AppColors.reminder),
                    ),
                  ),
                if (_resolvedLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _resolvedLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _geocoding ? null : _geocode,
                        icon: _geocoding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.travel_explore_rounded),
                        label: Text(
                          vet.hasCoordinates
                              ? 'Re-géocoder'
                              : 'Géocoder l’adresse',
                        ),
                      ),
                    ),
                  ],
                ),
                if (vet.hasCoordinates) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.vet,
                          ),
                          onPressed: _openMaps,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ouvrir Maps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Copier lat/lon',
                        onPressed: _copyCoords,
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader('Avis (${vet.reviews})', action: 'Voir tout'),
          const _Review(
            name: 'Julie M.',
            pet: '🐱 Mimi',
            text: 'Très à l\'écoute, ma chatte était détendue. Je recommande !',
            date: 'Il y a 2 jours',
          ),
          const _Review(
            name: 'Marc D.',
            pet: '🐶 Max',
            text: 'Explications claires et tarifs raisonnables. Super équipe.',
            date: 'Il y a 1 semaine',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            IconBadge(icon, color, size: 40),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;

  const _ServiceChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.vet.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.vet, fontWeight: FontWeight.w600)),
    );
  }
}

class _Review extends StatelessWidget {
  final String name;
  final String pet;
  final String text;
  final String date;

  const _Review({
    required this.name,
    required this.pet,
    required this.text,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(name[0],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      Text('$pet · $date',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                    Icon(Icons.star_rounded, color: AppColors.food, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(text,
                style: const TextStyle(color: AppColors.navy, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
