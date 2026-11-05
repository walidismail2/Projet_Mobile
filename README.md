# PetCare — Flutter + SQLite + Firebase

Application de gestion d’animaux domestiques.

## Architecture — moitié locale, moitié cloud

Règle : **SQLite** = journal privé du propriétaire (fonctionne hors ligne). **Firebase** = données partagées entre le propriétaire et le vétérinaire.

| SQLite (local) | Firebase |
|---|---|
| Vaccins, traitements, consultations | Compte Auth + profil `users` |
| Documents PDF / images (fichier sur le téléphone) | Fiche animal (copie, pour que le véto retrouve l’animal) |
| Repas du jour (fait / pas fait) | Régime prescrit + aliments autorisés / interdits |
| Rendez-vous | Annuaire des vétérinaires |
| Rappels | |

L’animal est **écrit d’abord en SQLite**, puis une copie (nom, espèce, puce, e-mail du propriétaire) part sur Firestore. Si le réseau coupe, l’app locale continue.

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

## Notifications

Alertes **locales** sur le téléphone (`flutter_local_notifications`), pas une simple liste.

- Vaccin : le matin du rappel (si la date est déjà passée, une alerte part tout de suite)
- Traitement : chaque jour à 9h, jusqu’à ce qu’il soit terminé
- Repas : chaque jour à l’heure du repas
- Rendez-vous : 1 h avant (si le créneau est déjà passé, une alerte part à la réservation)
- Rappel personnalisé : à la date et l’heure choisies

Les interrupteurs (types, son, vibration, 22h–7h) sont dans **Notifications → réglages**. Tout reste sur l’appareil.

## Lancer

```bash
flutter run
```

Pas de backend Node. Internet requis (Firebase).
