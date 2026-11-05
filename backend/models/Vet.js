const mongoose = require('mongoose');

const vetSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    specialty: { type: String, required: true },
    clinic: { type: String, required: true },
    address: { type: String, required: true },
    rating: { type: Number, required: true },
    reviews: { type: Number, required: true },
    distance: { type: String, required: true },
    experience: { type: Number, required: true },
    availableToday: { type: Boolean, default: false },
    price: { type: String, required: true },
    colorHex: { type: Number, default: 0xff4c7cf6 },
    image: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Vet', vetSchema);
