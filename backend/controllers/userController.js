const store = require('../store');

exports.getUsers = async (req, res) => {
  try {
    const data = store.load();
    res.status(200).json(
      data.users.map(({ password, ...u }) => ({
        id: u._id,
        username: u.username,
        email: u.email,
        phone: u.phone || '',
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.register = async (req, res) => {
  try {
    const { username, email, password, phone } = req.body;
    if (!username || !email || !password) {
      return res
        .status(400)
        .json({ message: 'username, email et password requis' });
    }
    const data = store.load();
    if (data.users.some((u) => u.email.toLowerCase() === email.toLowerCase())) {
      return res
        .status(409)
        .json({ message: 'Un compte existe déjà avec cet e-mail' });
    }
    const user = {
      _id: store.id(),
      username,
      email,
      password,
      phone: phone || '',
    };
    data.users.push(user);
    store.save(data);
    res.status(201).json({
      message: 'Compte créé',
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const data = store.load();
    const user = data.users.find(
      (u) => u.email.toLowerCase() === String(email || '').toLowerCase()
    );
    if (!user || user.password !== password) {
      return res.status(401).json({ message: 'Identifiants invalides' });
    }
    res.status(200).json({
      message: 'Connexion réussie',
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        phone: user.phone || '',
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.seedUsers = async () => {
  store.load();
};
