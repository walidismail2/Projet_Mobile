const store = require('../store');

exports.getAllMovies = async (req, res) => {
  try {
    const data = store.load();
    res.status(200).json(
      (data.movies || []).map((m) => ({
        _id: m._id,
        title: m.title,
        image: m.image,
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getOneMovie = async (req, res) => {
  try {
    const data = store.load();
    const movie = (data.movies || []).find((m) => m._id === req.params.id);
    if (!movie) {
      return res.status(404).json({ message: 'Film introuvable' });
    }
    res.status(200).json(movie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createMovie = async (req, res) => {
  try {
    const { title, description } = req.body;
    let imageUrl = '';
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    } else if (req.body.image) {
      imageUrl = req.body.image;
    } else {
      return res
        .status(400)
        .json({ message: 'Une image est requise pour créer un film.' });
    }
    const data = store.load();
    const movie = {
      _id: store.id(),
      title,
      image: imageUrl,
      description,
    };
    data.movies = data.movies || [];
    data.movies.push(movie);
    store.save(data);
    res.status(201).json(movie);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
