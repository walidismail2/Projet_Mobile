# PetCare Backend (Express + HTTP)

API adaptée depuis le TP movies pour PetCare.  
Stockage actuel : **fichier `data.json`** (pas besoin de MongoDB pour démarrer).

## Démarrer

```bash
cd backend
npm install
npm run dev
```

## Endpoints utiles

- `POST /users/register` `{ username, email, password, phone? }`
- `POST /users/login` `{ email, password }`
- `GET /vets` (query `?specialty=Généraliste`)
- `GET /vets/:id`

## Compte démo

- email : `sarah.benali@email.com`
- password : `password`

## Flutter baseUrl

- Téléphone USB : `adb reverse tcp:3000 tcp:3000` puis `http://127.0.0.1:3000`
- Émulateur Android : `http://10.0.2.2:3000`
- Téléphone Wi-Fi : `http://IP_PC:3000`
