# PetCare — Documentation des modules

Application Flutter **100 % SQLite** (pas de Firebase / pas de backend Node).  
Navigation propriétaire : 4 onglets — **Animaux · Santé · Alimentation · Compte**.

Fichier lié : `lib/STRUCTURE.md` (arborescence).

---

## Vue d’ensemble

| # | Module | Dossier | Rôle |
|---|---|---|---|
| — | **Core** (partagé) | `lib/core/` | SQLite, session, thème, widgets, shell |
| 1 | **Animaux** | `lib/modules/animaux/` | Animaux + boutique accessoires |
| 2 | **Santé** | `lib/modules/sante/` | Vaccins, traitements, documents, conseils météo |
| 3 | **Alimentation** | `lib/modules/alimentation/` | Repas + régime prescrit par le véto |
| 4 | **Compte (User)** | `lib/modules/compte/` | Auth, profil (photo + MDP), vétos OSM, RDV, notifs, rôle véto / admin |

Point d’entrée : `lib/main.dart`  
- restaure la session SQLite / SharedPreferences  
- ouvre `WelcomeScreen` ou `MainShell` (proprio) / `VetShell` (vétérinaire)

---

## Core — partagé (`lib/core/`)

Infrastructure utilisée par **tous** les modules.

### Data

| Fichier | Rôle |
|---|---|
| `data/app_database.dart` | Base `petcare.db` (création tables + migrations v1→v10) |
| `data/session.dart` | Utilisateur connecté en mémoire + sync prefs/SQLite |
| `data/auth_prefs.dart` | « Se souvenir de moi », préférences rappels |
| `data/app_refresh.dart` | Notifie les écrans quand les données changent |
| `data/document_storage.dart` | Sauvegarde locale des fichiers santé (PDF / images) |

### Models / Services / UI

| Fichier | Rôle |
|---|---|
| `models/models.dart` | Tous les modèles (`AppUser`, `Pet`, `Vaccine`, `Meal`, `Vet`, `Accessory`…) |
| `services/app_exception.dart` | Erreurs métier affichables |
| `services/local_notifications.dart` | Notifications locales (vaccins, repas, RDV, anniversaire…) |
| `theme/app_theme.dart` | Couleurs & thème Material 3 |
| `widgets/common.dart` | Widgets réutilisables (`AppCard`, `PetAvatar`, `UserAvatar`, `StatusPill`…) |
| `shell/main_shell.dart` | Barre de navigation des 4 modules |

---

## Module 1 — Animaux (`lib/modules/animaux/`)

### Objectif
Gérer les animaux du propriétaire + boutique d’accessoires (panier / achat local).

### CRUD
| Entité | Create | Read | Update | Delete |
|---|---|---|---|---|
| Animal | Formulaire ajout | Liste + fiche | Formulaire édition | Suppression + notif anniversaire |
| Accessoire | **Admin seulement** | Boutique filtrée | **Admin seulement** | **Admin seulement** |
| Panier | Proprio : ajouter | Onglet panier | Quantité +/- | Retirer / achat |

### Tables SQLite
- `pets`
- `accessories`
- `cart_items`

### Screens (pages)

| Fichier | Description |
|---|---|
| `screens/pets_list_screen.dart` | Liste des animaux + bouton **Accessoires** |
| `screens/pet_form_screen.dart` | Ajouter / modifier un animal (espèce, race API, photo + crop) |
| `screens/pet_detail_screen.dart` | Fiche : infos, idéal race/âge, poids, résumé santé |
| `screens/accessories_shop_screen.dart` | Boutique + panier (onglets), achat → MAJ stock |
| `screens/accessory_form_screen.dart` | CRUD d’un produit accessoire |

### Repositories

| Fichier | Description |
|---|---|
| `repositories/pet_repository.dart` | CRUD animaux par `owner_id` |
| `repositories/accessory_repository.dart` | Catalogue, panier, checkout (stock) |

### Services / APIs

| Fichier | API / logique | Usage |
|---|---|---|
| `services/breed_api_service.dart` | **Dog CEO** + **The Cat API** | Liste de races + image d’exemple |
| `services/pet_ideal_service.dart` | **Dog API** (`dogapi.dog`) + Cat API + fallback local | Poids / longévité / conseils selon âge |

### Flux clés
1. Ajout animal → choix espèce → chargement races HTTP → sauvegarde SQLite.  
2. Fiche animal → idéaux race/âge (API ou cache local).  
3. Accessoires → seed initial → panier → « Acheter » décrémente le stock.  
4. **Admin** (`admin@petcare.local` / `admin123`) : seul à pouvoir ajouter / modifier / supprimer des produits. Les comptes normaux achètent seulement.

---

## Module 2 — Santé (`lib/modules/sante/`)

### Objectif
Suivi santé par animal : vaccins, traitements, documents + conseil météo.

### CRUD
| Entité | Create | Read | Update | Delete |
|---|---|---|---|---|
| Vaccin | Formulaire / suggestion | Onglet Vaccins | Dialog édition | Oui (+ notif) |
| Traitement | Formulaire | Onglet Soins | Dialog + « Jour pris » | Oui |
| Document | Formulaire + fichier | Onglet Docs | — | Oui |

### Tables SQLite
- `vaccines`
- `treatments`
- `medical_documents`
- `health_tips_cache` (cache conseils météo)

### Screens

| Fichier | Description |
|---|---|
| `screens/health_screen.dart` | Sélecteur animal, bandeau météo, onglets Vaccins / Soins / Docs |
| `screens/add_health_record_screen.dart` | Ajout vaccin, traitement ou document |

### Repositories

| Fichier | Description |
|---|---|
| `repositories/health_repository.dart` | CRUD vaccins / traitements / documents + résumé santé |

### Services / APIs

| Fichier | API / logique | Usage |
|---|---|---|
| `services/health_tip_service.dart` | **Open-Meteo** | Conseil santé selon météo + espèce ; cache SQLite hors ligne ; lien `open-meteo.com` |
| `services/vaccine_suggestion_service.dart` | Référentiel **WSAVA** (liens) | Suggestions vaccins selon espèce + âge |

### Flux clés
1. Conseil météo du jour selon l’espèce sélectionnée.  
2. Suggestions de vaccins manquants → préremplissage à l’ajout.  
3. Documents stockés via `document_storage` (core).

---

## Module 3 — Alimentation (`lib/modules/alimentation/`)

### Objectif
Repas du jour côté propriétaire + régime / aliments prescrits par le vétérinaire.

### CRUD
| Entité | Create | Read | Update | Delete |
|---|---|---|---|---|
| Repas (`meals`) | Proprio | Liste du jour | Modifier / marquer « fait » | Oui |
| Régime (`diets`) | Véto (prescription) | Lecture proprio | Véto | — |
| Aliments (`food_items`) | Véto | Autorisés / interdits | Véto | — |

### Tables SQLite
- `meals`
- `diets`
- `food_items`

### Screens

| Fichier | Description |
|---|---|
| `screens/food_screen.dart` | Onglets Aujourd’hui / Autorisés / Interdits + résumé kcal / régime |
| `screens/add_meal_screen.dart` | Ajouter ou modifier un repas |

### Repositories

| Fichier | Description |
|---|---|
| `repositories/food_repository.dart` | CRUD repas + lecture régime/aliments pour le proprio |

### Services / APIs
Aucun service HTTP dédié dans ce module (données 100 % SQLite).  
La prescription se fait depuis le **module Compte → rôle vétérinaire**.

### Flux clés
| Qui | Action |
|---|---|
| Propriétaire | Ajoute / coche les repas |
| Vétérinaire | Cherche le proprio par e-mail → prescrit régime + aliments |
| Propriétaire | Voit le régime en lecture seule |

> Même appareil / même base SQLite requis (app offline).

---

## Module 4 — Compte / User (`lib/modules/compte/`)

### Objectif
Auth locale, profil, annuaire vétos (seed + OSM), rendez-vous, notifications, espace vétérinaire.

### CRUD (résumé)
| Entité | Create | Read | Update | Delete |
|---|---|---|---|---|
| Compte user | Inscription | Profil | Édition profil + photo + MDP | Déconnexion (session) |
| RDV | Booking | Liste à venir / historique | Modifier / statut | Supprimer |
| Rappels / notifs | Rappels perso | Liste + préférences | Marquer lu | Supprimer |
| Fiche véto annuaire | Inscription véto / seed / OSM | Recherche + fiche | Géocode coords | — |

### Tables SQLite
- `users` (profil + `password_hash` / `password_salt` + adresse / lat / lon + `photo_path`)
- `appointments`
- `notifications`
- `custom_reminders`
- `vets_cache`

### Screens — Auth

| Fichier | Description |
|---|---|
| `screens/auth/welcome_screen.dart` | Accueil (connexion / inscription) |
| `screens/auth/login_screen.dart` | Connexion + « Se souvenir de moi » |
| `screens/auth/register_screen.dart` | Inscription proprio (adresse/GPS) ou véto (cabinet) + reco véto proche |

### Screens — Profil

| Fichier | Description |
|---|---|
| `screens/profile/profile_screen.dart` | Hub Compte (avatar, RDV, vétos, infos, MDP, notifs, rappels, déconnexion) |
| `screens/profile/edit_profile_screen.dart` | Nom, email, téléphone, adresse/GPS (+ géocodage), photo + crop circulaire |
| `screens/profile/change_password_screen.dart` | Changer le mot de passe (actuel + nouveau, hash SQLite) |

### Screens — Vétérinaires (proprio)

| Fichier | Description |
|---|---|
| `screens/vets/vet_search_screen.dart` | Liste seed + **OSM/Overpass** autour de l’adresse |
| `screens/vets/vet_profile_screen.dart` | Fiche véto, géocode Nominatim, ouvrir Maps |
| `screens/vets/booking_screen.dart` | Prise de rendez-vous |

### Screens — RDV & notifications

| Fichier | Description |
|---|---|
| `screens/appointments/appointments_screen.dart` | RDV à venir / historique (menu ⋯ : modifier, terminé, annuler, supprimer) |
| `screens/notifications/notifications_screen.dart` | Centre de notifications |
| `screens/notifications/reminder_settings_screen.dart` | Préférences de rappels |
| `screens/notifications/custom_reminder_screen.dart` | Créer un rappel personnalisé |

### Screens — Rôle vétérinaire

| Fichier | Description |
|---|---|
| `screens/vet_role/vet_shell.dart` | Navigation de l’espace véto |
| `screens/vet_role/vet_patients_screen.dart` | Recherche propriétaire par e-mail |
| `screens/vet_role/vet_prescribe_screen.dart` | Prescription régime + aliments autorisés/interdits |

### Repositories

| Fichier | Description |
|---|---|
| `repositories/auth_repository.dart` | Login / register (hash SHA-256 + salt), reco véto proche |
| `repositories/user_repository.dart` | CRUD users SQLite |
| `repositories/vet_repository.dart` | Annuaire `vets_cache`, seed, merge OSM, plus proche |
| `repositories/appointment_repository.dart` | CRUD rendez-vous |
| `repositories/reminder_repository.dart` | Notifications + rappels perso |

### Data

| Fichier | Description |
|---|---|
| `data/vet_seed.dart` | Vétérinaires de démo (Paris + ESPRIT Ariana) avec coordonnées |

### Services / APIs

| Fichier | API | Usage |
|---|---|---|
| `services/geocoding_service.dart` | **Nominatim** (OpenStreetMap) | Adresse texte **ou** GPS (`36,6833, 10,3007`) → lat/lon ; reverse geocode |
| `services/overpass_vet_service.dart` | **Overpass** (+ fallback Nominatim) | Vrais cabinets `amenity=veterinary` / `healthcare=veterinary` autour de la position |

### Flux clés
1. Inscription proprio avec adresse/GPS → géocode → suggestion du véto le plus proche.  
2. Compte → Trouver un vétérinaire → Overpass/OSM + seed SQLite, triés par distance.  
3. Compte → photo de profil (galerie/caméra + crop circulaire) et changement de mot de passe (hash SQLite).  
4. Compte véto → prescrit régime dans Alimentation du proprio (même DB).

---

## APIs externes (valeur ajoutée)

| Module | API | Sans clé ? |
|---|---|---|
| Animaux | Dog CEO, The Cat API, Dog API | Oui |
| Santé | Open-Meteo | Oui |
| Compte | Nominatim, Overpass (OSM) | Oui |
| Alimentation | — | — |

Internet requis uniquement pour ces appels ; le reste fonctionne offline via SQLite.

---

## Auth & rôles

| Rôle | Écran principal | Peut faire |
|---|---|---|
| **Propriétaire** | `MainShell` (4 onglets) | Animaux, santé, repas, RDV, accessoires (achat) |
| **Vétérinaire** | `VetShell` | Chercher proprio, prescrire régime / aliments |
| **Admin** | `MainShell` | Comme proprio + CRUD catalogue accessoires |

Compte seed admin : `admin@petcare.local` / `admin123`.  
Mot de passe : **SHA-256 + salt**, stocké dans `users` (jamais en clair dans les prefs).  
Photo profil : chemin local `users.photo_path` (même principe que `pets.photo_path`).

---

## Lancer le projet

```bash
flutter pub get
flutter run
```

Base locale : `petcare.db` (documents de l’app).
