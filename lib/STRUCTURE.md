# Structure PetCare (`lib/`)

```
lib/
  main.dart
  core/                         # partagé (tous les modules)
    data/                       # SQLite, session, prefs, storage
    models/                     # modèles communs
    services/                   # exceptions, notifications locales
    shell/                      # navigation 4 onglets
    theme/
    widgets/
  modules/
    animaux/                    # Module 1
      screens/
      repositories/
      services/                 # Dog CEO, Cat API, idéaux race
    sante/                      # Module 2
      screens/
      repositories/
      services/                 # Open-Meteo, suggestions vaccins
    alimentation/               # Module 3
      screens/
      repositories/
    compte/                     # Module 4 (User)
      screens/
        auth/
        profile/
        vets/
        appointments/
        notifications/
        vet_role/               # espace compte vétérinaire
      repositories/
      services/                 # Nominatim, Overpass
      data/                     # seed vétos
```

Imports : `package:flutter_example/...` (nom du package dans `pubspec.yaml`).
