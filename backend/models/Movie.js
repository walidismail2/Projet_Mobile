const mongoose = require('mongoose');

const movieSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    image: { type: String, required: true }, // URL de l'image
    description: { type: String, required: true }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Movie', movieSchema);