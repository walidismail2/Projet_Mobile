/// Base locale « Peut-il manger ça ? » (hors ligne).
///
/// Sources de référence : ASPCA Animal Poison Control (« People Foods to
/// Avoid Feeding Your Pets »), Pet Poison Helpline, WSAVA. Informations
/// générales — ne remplacent pas l'avis du vétérinaire.
library;

enum FoodRisk {
  /// Toxique : ne jamais donner.
  toxic,

  /// À éviter / seulement en très petite quantité.
  caution,

  /// Généralement sans danger, nature et en petite quantité.
  safe,
}

class FoodFact {
  /// Nom affiché.
  final String title;
  final String emoji;

  /// Noms reconnus (FR + EN pour les listes d'ingrédients), sans accents.
  final List<String> names;
  final FoodRisk dog;
  final FoodRisk cat;
  final String reason;

  const FoodFact({
    required this.title,
    required this.emoji,
    required this.names,
    required this.dog,
    required this.cat,
    required this.reason,
  });

  FoodRisk riskFor(String species) => switch (species) {
    'Chien' => dog,
    'Chat' => cat,
    // Autre espèce : on retient le cas le plus prudent.
    _ => dog.index < cat.index ? dog : cat,
  };
}

const foodFacts = <FoodFact>[
  // ——— Toxiques ———
  FoodFact(
    title: 'Chocolat, cacao',
    emoji: '🍫',
    names: ['chocolat', 'cacao', 'chocolate', 'cocoa'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'Théobromine et caféine : vomissements, agitation, troubles du '
        'rythme cardiaque, convulsions. Le chocolat noir est le plus dangereux.',
  ),
  FoodFact(
    title: 'Raisin, raisins secs',
    emoji: '🍇',
    names: ['raisin', 'raisin sec', 'grape', 'sultana', 'currant'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'Peut provoquer une insuffisance rénale aiguë, même en petite '
        'quantité. Aucune dose n’est considérée comme sûre.',
  ),
  FoodFact(
    title: 'Oignon, ail, poireau, échalote, ciboulette',
    emoji: '🧅',
    names: [
      'oignon',
      'ail',
      'poireau',
      'echalote',
      'ciboulette',
      'onion',
      'garlic',
      'leek',
      'shallot',
      'chive',
    ],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'Détruisent les globules rouges (anémie), crus, cuits ou en '
        'poudre. Les chats sont encore plus sensibles.',
  ),
  FoodFact(
    title: 'Xylitol (chewing-gum, bonbons sans sucre)',
    emoji: '🍬',
    names: ['xylitol', 'chewing-gum', 'chewing gum', 'bonbon sans sucre'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.caution,
    reason:
        'Chez le chien : chute brutale du sucre dans le sang et atteinte '
        'du foie en quelques minutes à heures.',
  ),
  FoodFact(
    title: 'Noix de macadamia',
    emoji: '🌰',
    names: ['macadamia'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.caution,
    reason: 'Faiblesse des pattes arrière, tremblements, fièvre, vomissements.',
  ),
  FoodFact(
    title: 'Alcool (bière, vin…)',
    emoji: '🍺',
    names: ['alcool', 'biere', 'vin', 'alcohol', 'beer', 'wine'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'Vomissements, désorientation, hypothermie, coma ; très faible '
        'dose suffisante pour un petit animal.',
  ),
  FoodFact(
    title: 'Café, thé, caféine',
    emoji: '☕',
    names: [
      'cafe',
      'the',
      'cafeine',
      'boisson energisante',
      'coffee',
      'tea',
      'caffeine',
    ],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason: 'La caféine provoque agitation, tachycardie, tremblements.',
  ),
  FoodFact(
    title: 'Pâte à pain crue, levure',
    emoji: '🍞',
    names: ['pate crue', 'pate a pain', 'levure', 'yeast dough'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'La pâte gonfle dans l’estomac et la fermentation produit de '
        'l’alcool.',
  ),
  FoodFact(
    title: 'Médicaments humains (paracétamol, ibuprofène)',
    emoji: '💊',
    names: [
      'paracetamol',
      'doliprane',
      'ibuprofene',
      'ibuprofen',
      'aspirine',
      'medicament',
    ],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason:
        'Ne jamais donner sans avis vétérinaire. Le paracétamol peut être '
        'mortel pour un chat, même à faible dose.',
  ),
  FoodFact(
    title: 'Lys (plante, fleurs, pollen)',
    emoji: '🌸',
    names: ['lys', 'lily', 'lilies'],
    dog: FoodRisk.caution,
    cat: FoodRisk.toxic,
    reason:
        'Chez le chat, toute la plante (même le pollen ou l’eau du vase) '
        'peut entraîner une insuffisance rénale aiguë.',
  ),
  FoodFact(
    title: 'Rhubarbe (feuilles)',
    emoji: '🥬',
    names: ['rhubarbe', 'rhubarb'],
    dog: FoodRisk.toxic,
    cat: FoodRisk.toxic,
    reason: 'Les oxalates des feuilles atteignent les reins.',
  ),
  FoodFact(
    title: 'Huiles essentielles',
    emoji: '🧴',
    names: ['huile essentielle', 'tea tree', 'essential oil'],
    dog: FoodRisk.caution,
    cat: FoodRisk.toxic,
    reason:
        'Les chats ne savent pas les éliminer (foie) : intoxication même '
        'par diffusion ou contact.',
  ),

  // ——— À éviter ———
  FoodFact(
    title: 'Avocat',
    emoji: '🥑',
    names: ['avocat', 'avocado'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Persine (troubles digestifs), très gras, et le noyau peut '
        'boucher l’intestin.',
  ),
  FoodFact(
    title: 'Os cuits',
    emoji: '🦴',
    names: ['os cuit', 'os de poulet', 'os de lapin', 'cooked bone'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Ils éclatent en esquilles : blessures de la bouche, obstruction '
        'ou perforation de l’intestin.',
  ),
  FoodFact(
    title: 'Lait, fromage, crème',
    emoji: '🧀',
    names: [
      'lait',
      'fromage',
      'creme',
      'yaourt',
      'beurre',
      'milk',
      'cheese',
      'cream',
    ],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'La plupart des adultes digèrent mal le lactose : diarrhée. Un '
        'petit morceau de fromage reste généralement toléré.',
  ),
  FoodFact(
    title: 'Aliments gras, charcuterie',
    emoji: '🥓',
    names: [
      'gras',
      'charcuterie',
      'bacon',
      'saucisse',
      'peau de poulet',
      'friture',
      'frites',
    ],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Risque de pancréatite (inflammation du pancréas) et de '
        'surpoids ; souvent très salé.',
  ),
  FoodFact(
    title: 'Sel, chips, plats très salés',
    emoji: '🧂',
    names: ['sel', 'chips', 'salt'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'En grande quantité : soif intense, vomissements, intoxication '
        'au sodium.',
  ),
  FoodFact(
    title: 'Noix de muscade',
    emoji: '🌰',
    names: ['muscade', 'nutmeg'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason: 'La myristicine peut provoquer tremblements et désorientation.',
  ),
  FoodFact(
    title: 'Noyaux et pépins (cerise, abricot, pomme…)',
    emoji: '🍒',
    names: ['noyau', 'pepin', 'cerise', 'cherry'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Contiennent des composés cyanogènes et peuvent boucher '
        'l’intestin. La chair des fruits sans noyau pose moins de problème.',
  ),
  FoodFact(
    title: 'Poisson cru',
    emoji: '🐟',
    names: ['poisson cru', 'sushi', 'raw fish'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Parasites ; chez le chat, une enzyme détruit la vitamine B1 '
        '(carence si donné souvent).',
  ),
  FoodFact(
    title: 'Œuf cru, viande crue',
    emoji: '🥚',
    names: ['oeuf cru', 'viande crue', 'raw egg', 'raw meat'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Salmonelles, E. coli, parasites. Le blanc d’œuf cru gêne aussi '
        'l’absorption de la biotine.',
  ),
  FoodFact(
    title: 'Champignons sauvages',
    emoji: '🍄',
    names: ['champignon', 'mushroom'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'Certains champignons sauvages sont mortels. Les champignons de '
        'Paris nature du commerce sont en général tolérés.',
  ),
  FoodFact(
    title: 'Tomate verte, pomme de terre crue',
    emoji: '🍅',
    names: [
      'tomate verte',
      'feuille de tomate',
      'pomme de terre crue',
      'green tomato',
      'raw potato',
    ],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason:
        'La solanine (parties vertes, crues) irrite le tube digestif. '
        'Tomate mûre et pomme de terre cuite nature : en petite quantité.',
  ),
  FoodFact(
    title: 'Agrumes (citron, orange…)',
    emoji: '🍋',
    names: ['citron', 'orange', 'pamplemousse', 'agrume', 'lemon', 'citrus'],
    dog: FoodRisk.caution,
    cat: FoodRisk.caution,
    reason: 'Acides et huiles essentielles de l’écorce : troubles digestifs.',
  ),

  // ——— Généralement sans danger (nature, sans assaisonnement) ———
  FoodFact(
    title: 'Carotte',
    emoji: '🥕',
    names: ['carotte', 'carrot'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason: 'Crue ou cuite, coupée en petits morceaux ; peu calorique.',
  ),
  FoodFact(
    title: 'Haricots verts, courgette, concombre',
    emoji: '🥒',
    names: ['haricot vert', 'courgette', 'concombre', 'green bean', 'zucchini'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason:
        'Nature, cuits à l’eau ou crus en petits morceaux ; utile pour '
        'les régimes minceur.',
  ),
  FoodFact(
    title: 'Potiron, citrouille',
    emoji: '🎃',
    names: ['potiron', 'citrouille', 'courge', 'pumpkin'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason:
        'Cuit et nature (pas de préparation pour tarte, souvent sucrée '
        'et épicée).',
  ),
  FoodFact(
    title: 'Riz cuit',
    emoji: '🍚',
    names: ['riz', 'rice'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason:
        'Cuit à l’eau, sans sel ; souvent conseillé en cas de digestion '
        'difficile.',
  ),
  FoodFact(
    title: 'Poulet, dinde cuits (sans os ni peau)',
    emoji: '🍗',
    names: ['poulet', 'dinde', 'chicken', 'turkey'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason: 'Cuits à l’eau, sans assaisonnement, sans os ni peau.',
  ),
  FoodFact(
    title: 'Poisson cuit (sans arêtes)',
    emoji: '🐠',
    names: ['poisson cuit', 'saumon cuit', 'cooked fish'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason: 'Cuit, sans arêtes ni assaisonnement.',
  ),
  FoodFact(
    title: 'Œuf cuit',
    emoji: '🍳',
    names: ['oeuf cuit', 'oeuf dur', 'cooked egg'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason: 'Dur ou brouillé sans matière grasse ni sel.',
  ),
  FoodFact(
    title: 'Pomme (sans trognon ni pépins)',
    emoji: '🍎',
    names: ['pomme', 'apple'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason: 'En petits morceaux, épluchée, sans trognon ni pépins.',
  ),
  FoodFact(
    title: 'Banane, myrtilles, pastèque',
    emoji: '🍌',
    names: ['banane', 'myrtille', 'pasteque', 'banana', 'blueberr'],
    dog: FoodRisk.safe,
    cat: FoodRisk.safe,
    reason:
        'En friandise occasionnelle (sucre) ; pastèque sans pépins ni '
        'écorce.',
  ),
];
