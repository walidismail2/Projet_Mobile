const store = require('../store');

exports.getAllVets = async (req, res) => {
  try {
    const { specialty } = req.query;
    const data = store.load();
    let vets = data.vets || [];
    if (specialty && specialty !== 'Tous') {
      vets = vets.filter((v) => v.specialty === specialty);
    }
    vets = [...vets].sort((a, b) => b.rating - a.rating);
    res.status(200).json(vets);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getOneVet = async (req, res) => {
  try {
    const data = store.load();
    const vet = (data.vets || []).find((v) => v._id === req.params.id);
    if (!vet) {
      return res.status(404).json({ message: 'Vétérinaire introuvable' });
    }
    res.status(200).json(vet);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createVet = async (req, res) => {
  try {
    const data = store.load();
    const vet = { _id: store.id(), ...req.body };
    data.vets.push(vet);
    store.save(data);
    res.status(201).json(vet);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.seedVets = async () => {
  store.load();
};
