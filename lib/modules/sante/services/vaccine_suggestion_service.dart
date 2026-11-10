import 'package:flutter_example/core/models/models.dart';

class VaccineSuggestion {
  final String name;
  final String reason;
  final String sourceLabel;
  final String sourceUrl;
  final int suggestedIntervalMonths;

  const VaccineSuggestion({
    required this.name,
    required this.reason,
    required this.sourceLabel,
    required this.sourceUrl,
    this.suggestedIntervalMonths = 12,
  });
}

/// Suggestions de vaccins selon espèce + âge (référentiel WSAVA / bonnes pratiques).
class VaccineSuggestionService {
  static const wsavaUrl =
      'https://wsava.org/global-guidelines/vaccination-guidelines/';
  static const wsavaLabel = 'WSAVA Vaccination Guidelines';

  List<VaccineSuggestion> suggestionsFor(Pet pet) {
    final months = _ageInMonths(pet.birthDate);
    return switch (pet.species) {
      'Chien' => _dog(months),
      'Chat' => _cat(months),
      'Lapin' => _rabbit(months),
      _ => _generic(pet.species, months),
    };
  }

  List<VaccineSuggestion> missingFor({
    required Pet pet,
    required List<Vaccine> recorded,
  }) {
    final recordedNames = recorded.map((v) => _norm(v.name)).toSet();
    return suggestionsFor(pet).where((s) {
      final n = _norm(s.name);
      return !recordedNames.any((r) => r.contains(n) || n.contains(r));
    }).toList();
  }

  List<VaccineSuggestion> _dog(int months) {
    if (months < 4) {
      return const [
        VaccineSuggestion(
          name: 'CHPP (maladie de Carré, hépatite, parvo, para-influenza)',
          reason: 'Chiot < 4 mois : primo-vaccination de base (core vaccines).',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 1,
        ),
        VaccineSuggestion(
          name: 'Rage',
          reason: 'Souvent dès 12 semaines selon la réglementation locale.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
      ];
    }
    if (months < 12) {
      return const [
        VaccineSuggestion(
          name: 'CHPP — rappel jeune',
          reason: 'Jeune chien : terminer le protocole de primo-vaccination.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
        VaccineSuggestion(
          name: 'Rage',
          reason: 'Rappel annuel ou selon législation / carnet.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
        VaccineSuggestion(
          name: 'Leptospirose',
          reason: 'Risque environnemental : souvent recommandé selon le mode de vie.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
      ];
    }
    if (months >= 7 * 12) {
      return const [
        VaccineSuggestion(
          name: 'CHPP — rappel adulte / senior',
          reason: 'Senior : espacement possible selon bilan véto (souvent 1–3 ans).',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 36,
        ),
        VaccineSuggestion(
          name: 'Rage',
          reason: 'Maintenir à jour selon obligation légale.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
      ];
    }
    return const [
      VaccineSuggestion(
        name: 'CHPP — rappel',
        reason: 'Adulte : rappel des vaccins core selon protocole véto.',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 36,
      ),
      VaccineSuggestion(
        name: 'Rage',
        reason: 'Rappel selon réglementation et carnet de santé.',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
      VaccineSuggestion(
        name: 'Leptospirose',
        reason: 'Souvent annuelle si risque (eau, campagne, rongeurs).',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
    ];
  }

  List<VaccineSuggestion> _cat(int months) {
    if (months < 4) {
      return const [
        VaccineSuggestion(
          name: 'RCP (rhinotrachéite, calicivirus, panleucopénie)',
          reason: 'Chaton : primo-vaccination core.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 1,
        ),
        VaccineSuggestion(
          name: 'Rage',
          reason: 'Selon réglementation / voyages.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
      ];
    }
    if (months < 12) {
      return const [
        VaccineSuggestion(
          name: 'RCP — rappel jeune',
          reason: 'Terminer le protocole chaton.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
        VaccineSuggestion(
          name: 'Leucose (FeLV)',
          reason: 'Recommandé si accès extérieur / contact avec d’autres chats.',
          sourceLabel: wsavaLabel,
          sourceUrl: wsavaUrl,
          suggestedIntervalMonths: 12,
        ),
      ];
    }
    return const [
      VaccineSuggestion(
        name: 'RCP — rappel',
        reason: 'Adulte / senior : rappel core selon avis véto.',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 36,
      ),
      VaccineSuggestion(
        name: 'Rage',
        reason: 'Maintenir à jour si obligatoire ou voyages.',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
      VaccineSuggestion(
        name: 'Leucose (FeLV)',
        reason: 'Selon mode de vie (extérieur / collectivité).',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
    ];
  }

  List<VaccineSuggestion> _rabbit(int months) {
    return const [
      VaccineSuggestion(
        name: 'Myxomatose / VHD',
        reason: 'Lapin : vaccins fréquents selon zone et risque épidémique.',
        sourceLabel: 'WSAVA / bonnes pratiques NAC',
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
    ];
  }

  List<VaccineSuggestion> _generic(String species, int months) {
    return [
      VaccineSuggestion(
        name: 'Bilan vaccinal $species',
        reason: months < 12
            ? 'Jeune animal : demande un protocole adapté à l’espèce au véto.'
            : 'Vérifie avec le véto les vaccins recommandés pour cette espèce.',
        sourceLabel: wsavaLabel,
        sourceUrl: wsavaUrl,
        suggestedIntervalMonths: 12,
      ),
    ];
  }

  int _ageInMonths(String birthDate) {
    final birth = parseFrDate(birthDate);
    if (birth == null) return 24;
    final now = DateTime.now();
    var months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) months -= 1;
    return months.clamp(0, 400);
  }

  String _norm(String s) => s.toLowerCase().trim();
}
