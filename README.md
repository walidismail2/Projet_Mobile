# PetCare — Flutter + SQLite + Firebase

Application de gestion d’animaux domestiques.

## Architecture

- **Propriétaire** : animaux / santé / repas (suivi) / RDV — SQLite + sync animaux Firestore
- **Vétérinaire** : prescrit **régime** + aliments autorisés/interdits (Firestore)
- **Firebase Auth** : comptes `owner` ou `vet`
- **Firestore** : profils, animaux (cloud), régimes, aliments, annuaire vétos (recherche RDV)
- **SQLite** : santé (vaccins, traitements, consultations, documents), repas, RDV, cache vétos

Onglets propriétaire : Accueil, Animaux, Santé, RDV, Repas.

## Santé

Données locales (SQLite), par animal.

- **Vaccins** : statut calculé depuis la date du rappel — À jour, Bientôt (≤ 30 jours), En retard
- **Traitements** : dosage, fréquence, durée, bouton « Jour pris », barre de progression
- **Consultations** : motif + compte rendu
- **Documents** : upload **PDF** (fichiers) ou **image** (galerie / photo), copie locale, ouverture dans l’app
- Suppression de chaque entrée ; résumé vaccins / traitements sur la fiche animal

Pas de carte Google Maps : l’annuaire affiche l’adresse en texte.

## Créer un compte vétérinaire

1. Dans l’app → **Inscription**
2. Choisis **Vétérinaire** (segmented button)
3. Remplis spécialité, clinique, adresse, services, horaires, téléphone → confirme l’e-mail
4. **Connexion** → tu arrives dans l’**Espace vétérinaire** (la fiche est publiée dans l’annuaire)
5. Cherche le propriétaire par **e-mail** → ouvre un animal → prescrit le régime

> Différent de l’annuaire « Dr. Claire Martin… » (fiches pour prendre RDV).  
> Le **compte véto** = login pour **prescrire**. L’annuaire = liste publique Firestore `vets`.

### Alternative console Firebase

1. Authentication → ajoute un user (e-mail/mdp)
2. Firestore → `users/{uid}` avec champs :
   - `username`, `email`, `role: "vet"`

## Flux alimentation

| Qui | Fait quoi |
|---|---|
| Propriétaire | Ajoute repas du jour (SQLite) |
| Vétérinaire | Prescrit régime + autorisés/interdits (Firestore) |
| Propriétaire | Voit le régime en **lecture seule** dans Alimentation |

## Règles Firestore (démo)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /vets/{id} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /pets/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /pet_diets/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /pet_food_items/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Lancer

```bash
flutter run
```

Pas de backend Node. Internet requis (Firebase).
