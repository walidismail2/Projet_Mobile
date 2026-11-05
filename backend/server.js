require('dotenv').config();

const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const userRoutes = require('./routes/userRoutes');
const movieRoutes = require('./routes/movieRoutes');
const vetRoutes = require('./routes/vetRoutes');
const userController = require('./controllers/userController');
const vetController = require('./controllers/vetController');

const app = express();
const PORT = process.env.PORT || 3000;

const uploadsDir = path.join(__dirname, 'public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));
app.use(express.static(path.join(__dirname, 'public')));

userController.seedUsers();
vetController.seedVets();
console.log('Store JSON prêt (data.json) — pas besoin de MongoDB');

app.use('/users', userRoutes);
app.use('/movies', movieRoutes);
app.use('/vets', vetRoutes);

app.get('/health', (_req, res) => res.json({ ok: true, storage: 'json' }));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Serveur PetCare démarré sur http://localhost:${PORT}`);
});
