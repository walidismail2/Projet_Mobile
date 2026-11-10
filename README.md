# PetCare — Flutter + SQLite

Application de gestion d’animaux domestiques. **100 % local** : Auth, données et annuaire tournent sur **SQLite** (pas de Firebase / pas de backend Node).

Docs détaillées : **`MODULES.md`** (chaque module, pages, services, tables, APIs) · `lib/STRUCTURE.md` (arborescence).

## Valeur ajoutée — API externes

### Module Animaux
Boutique **Accessoires** (SQLite) : catalogue, panier, quantités, achat (stock).  
CRUD produit réservé au compte **admin** (`admin@petcare.local` / `admin123`).

À l’ajout / édition d’un **Chien** ou **Chat** :
- races via **Dog CEO** ou **The Cat API**
- photo locale (galerie / caméra + crop circulaire) → `pets.photo_path`
- photo d’exemple HTTP → race sauvée en SQLite (`pets.breed`)

Sur la **fiche animal** → section **Idéal race & âge** :
- Chiens : [Dog API](https://dogapi.dog) (poids, durée de vie, exercice)
- Chats : The Cat API (poids / longévité)
- + conseils selon l’âge (chiot/chaton, adulte, senior) ; fallback local si API KO

### Module Santé
- Conseil météo compact via [Open-Meteo](https://open-meteo.com/) (lien cliquable)
- Suggestions de vaccins selon espèce + âge ([WSAVA](https://wsava.org/global-guidelines/vaccination-guidelines/))
- Cache SQLite hors ligne (`health_tips_cache`)

### Module Compte
- Inscription propriétaire → **adresse** ou GPS (`36,6833, 10,3007`) via [Nominatim](https://nominatim.openstreetmap.org) → recommandation du **vétérinaire le plus proche**
- **Trouver un vétérinaire** → [Overpass / OpenStreetMap](https://wiki.openstreetmap.org/wiki/Overpass_API) liste les vrais cabinets `amenity=veterinary` autour de l’adresse (+ seed SQLite, fallback Nominatim, cache local)
- Fiche vétérinaire → géocoder l’adresse, sauve lat/lon en SQLite, bouton **Ouvrir Maps**
- Profil : **photo** (même principe que les animaux) + **modifier le mot de passe**

## Architecture code

```
lib/
  core/                 # data SQLite, session, theme, widgets, shell
  modules/
    animaux/            # screens + repositories + APIs races
    sante/              # screens + repositories + Open-Meteo / vaccins
    alimentation/       # screens + repositories
    compte/             # auth, profil (photo/MDP), vétos OSM, RDV, notifs, rôle véto
```

Tout est stocké dans `petcare.db` sur l’appareil (migrations jusqu’à **v10**).

| Module | Tables SQLite |
|---|---|
| **1. Animaux** | `pets`, `accessories`, `cart_items` |
| **2. Santé** | `vaccines`, `treatments`, `medical_documents`, `health_tips_cache` |
| **3. Alimentation** | `meals`, `diets`, `food_items` |
| **4. Compte** | `users` (hash + adresse/GPS + `photo_path`), `appointments`, `notifications`, `custom_reminders`, `vets_cache` |

## 4 modules — CRUD + SQLite

| # | Module | Create | Read | Update | Delete |
|---|---|---|---|---|---|
| 1 | **Animaux** | Animal + panier (+ accessoire **admin**) | Liste + boutique | Modifier | Supprimer |
| 2 | **Santé** | Vaccin / traitement / document | Onglets | Modifier | Supprimer |
| 3 | **Alimentation** | Ajouter un repas | Liste + régime | Modifier + « fait » | Supprimer |
| 4 | **Compte** | Inscription + RDV + rappel | Profil / notifs / RDV | Profil, photo, MDP, RDV | Supprimer RDV / notif |

Navigation : 4 onglets — Animaux, Santé, Alimentation, Compte.

## Auth locale

- Inscription / connexion en **SQLite** (`users` + hash SHA-256 + salt)
- Rôles : **propriétaire**, **vétérinaire**, **admin**
- Compte véto → fiche ajoutée dans l’annuaire local (`vets_cache`)
- Session « Se souvenir de moi » via SharedPreferences (pas le mot de passe)
- Changement de mot de passe depuis Compte → Profil

## Santé

Données locales par animal : vaccins, traitements, documents PDF/images.
Onglets : Vaccins, Soins, Docs (+ bandeau conseil météo).

## Flux alimentation

| Qui | Fait quoi |
|---|---|
| Propriétaire | Ajoute les repas du jour (`meals`) |
| Vétérinaire | Cherche le propriétaire par e-mail (même base SQLite) et prescrit régime + aliments (`diets`, `food_items`) |
| Propriétaire | Voit le régime en lecture seule dans Alimentation |

> Proprio et véto doivent utiliser **le même appareil / la même base** pour la prescription (app 100 % offline).

## Annuaire vétos

Seed local (`Dr. Claire Martin…` + ESPRIT Ariana) dans `vets_cache` au premier lancement.  
Recherche OSM via Overpass ; pas de carte Google Maps intégrée : adresse texte + **Ouvrir Maps**.

## Notifications

Alertes locales (`flutter_local_notifications`) : vaccins, traitements, repas, RDV, anniversaires, rappels personnalisés.

## Lancer

```bash
flutter pub get
flutter run
```

100 % SQLite (pas de backend Node). Internet utile pour les APIs (races, météo, OSM).
