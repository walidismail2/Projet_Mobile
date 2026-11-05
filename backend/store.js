const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const FILE = path.join(__dirname, 'data.json');

function load() {
  if (!fs.existsSync(FILE)) {
    const seed = {
      users: [
        {
          _id: 'u_demo',
          username: 'Sarah Benali',
          email: 'sarah.benali@email.com',
          password: 'password',
          phone: '+33 6 12 34 56 78',
        },
      ],
      vets: [
        {
          _id: 'v1',
          name: 'Dr. Claire Martin',
          specialty: 'Généraliste',
          clinic: 'Clinique VetCare',
          address: '12 rue des Lilas, 75011 Paris',
          rating: 4.9,
          reviews: 214,
          distance: '1,2 km',
          experience: 12,
          availableToday: true,
          price: '45 €',
          colorHex: 0xff4c7cf6,
          image: '',
        },
        {
          _id: 'v2',
          name: 'Dr. Thomas Leroy',
          specialty: 'Chirurgie',
          clinic: 'Centre Vétérinaire Bastille',
          address: '48 bd Voltaire, 75011 Paris',
          rating: 4.7,
          reviews: 158,
          distance: '2,5 km',
          experience: 15,
          availableToday: false,
          price: '60 €',
          colorHex: 0xff8b5cf6,
          image: '',
        },
        {
          _id: 'v3',
          name: 'Dr. Inès Haddad',
          specialty: 'NAC',
          clinic: 'Clinique des Petits Compagnons',
          address: '5 av. de la République, 75003 Paris',
          rating: 4.8,
          reviews: 97,
          distance: '3,1 km',
          experience: 8,
          availableToday: true,
          price: '50 €',
          colorHex: 0xff2ebd85,
          image: '',
        },
        {
          _id: 'v4',
          name: 'Dr. Paul Moreau',
          specialty: 'Dentaire',
          clinic: 'Dentivet Paris',
          address: '30 rue Oberkampf, 75011 Paris',
          rating: 4.6,
          reviews: 73,
          distance: '4,0 km',
          experience: 10,
          availableToday: false,
          price: '55 €',
          colorHex: 0xffffa928,
          image: '',
        },
      ],
      movies: [],
    };
    fs.writeFileSync(FILE, JSON.stringify(seed, null, 2));
    return seed;
  }
  return JSON.parse(fs.readFileSync(FILE, 'utf8'));
}

function save(data) {
  fs.writeFileSync(FILE, JSON.stringify(data, null, 2));
}

function id() {
  return crypto.randomBytes(8).toString('hex');
}

module.exports = { load, save, id };
