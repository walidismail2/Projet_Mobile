import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'add_health_record_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int _pet = 0;

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter au dossier médical',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final type in HealthRecordType.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconBadge(type.icon, type.color, size: 44),
                  title: Text(type.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  subtitle: Text(type.description),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                          builder: (_) => AddHealthRecordScreen(type: type)),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = MockData.pets[_pet];
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddSheet,
          child: const Icon(Icons.add_rounded),
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Text('Santé',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    PetSelector(
                      selected: _pet,
                      onChanged: (i) => setState(() => _pet = i),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _HealthSummary(pet: pet),
                    ),
                  ],
                ),
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: PinnedTabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      Tab(text: 'Vaccins'),
                      Tab(text: 'Traitements'),
                      Tab(text: 'Historique'),
                      Tab(text: 'Allergies & infos'),
                      Tab(text: 'Documents'),
                    ],
                  ),
                ),
              ),
            ],
            body: const TabBarView(
              children: [
                _VaccinesTab(),
                _TreatmentsTab(),
                _HistoryTab(),
                _AllergiesTab(),
                _DocumentsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  final Pet pet;

  const _HealthSummary({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3FD19A), AppColors.health],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  constraints:
                      const BoxConstraints.tightFor(width: 70, height: 70),
                ),
                const Text('75%',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carnet de santé de ${pet.name}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text('3 vaccins sur 4 à jour',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Prochain rappel : 10/10/2026',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccinesTab extends StatelessWidget {
  const _VaccinesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        for (final v in MockData.vaccines)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  const IconBadge(Icons.vaccines_rounded, AppColors.health),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Fait le ${v.date} · ${v.vet}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text('Rappel : ${v.nextDate}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy)),
                      ],
                    ),
                  ),
                  switch (v.status) {
                    HealthStatus.upToDate =>
                      const StatusPill('À jour', AppColors.health),
                    HealthStatus.soon =>
                      const StatusPill('Bientôt', AppColors.food),
                    HealthStatus.late =>
                      const StatusPill('En retard', AppColors.reminder),
                  },
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TreatmentsTab extends StatelessWidget {
  const _TreatmentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        for (final t in MockData.treatments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(t.icon, AppColors.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            Text('${t.dosage} · ${t.frequency}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: t.currentDay / t.totalDays,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.purple.withValues(alpha: 0.12),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.purple),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t.currentDay == t.totalDays
                            ? 'Terminé'
                            : 'Jour ${t.currentDay}/${t.totalDays}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final events = MockData.medicalHistory;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(e.icon, color: Colors.white, size: 20),
                  ),
                  if (i != events.length - 1)
                    Expanded(
                      child: Container(width: 2, color: AppColors.border),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.date,
                            style: TextStyle(
                                color: e.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(e.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(e.description,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AllergiesTab extends StatelessWidget {
  const _AllergiesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        const SectionHeader('Allergies'),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AllergyChip('Poulet', 'Sévère', AppColors.reminder),
            _AllergyChip('Pollen', 'Modérée', AppColors.food),
            _AllergyChip('Pénicilline', 'Sévère', AppColors.reminder),
            _AllergyChip('Acariens', 'Légère', AppColors.health),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader('Informations importantes'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const Column(
            children: [
              InfoRow(Icons.bloodtype_rounded, 'Groupe sanguin', 'DEA 1.1+'),
              Divider(height: 1),
              InfoRow(Icons.monitor_heart_rounded, 'Maladie chronique',
                  'Dysplasie légère'),
              Divider(height: 1),
              InfoRow(Icons.no_food_rounded, 'Régime spécial',
                  'Hypoallergénique'),
              Divider(height: 1),
              InfoRow(Icons.local_hospital_rounded, 'Vétérinaire référent',
                  'Dr. Martin'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.reminder.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.reminder.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.reminder, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ne jamais administrer de pénicilline. Réaction allergique grave constatée en 2025.',
                  style: TextStyle(color: AppColors.navy, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllergyChip extends StatelessWidget {
  final String name;
  final String severity;
  final Color color;

  const _AllergyChip(this.name, this.severity, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(width: 6),
          Text(severity, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.95,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddHealthRecordScreen(type: HealthRecordType.document),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded,
                    color: AppColors.primary, size: 40),
                SizedBox(height: 8),
                Text('Importer un\ndocument',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        for (final d in MockData.documents)
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (d.isPdf ? AppColors.reminder : AppColors.vet)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      d.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      size: 40,
                      color: d.isPdf ? AppColors.reminder : AppColors.vet,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text('${d.date} · ${d.size}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}
