const express = require('express');
const router = express.Router();
const movieController = require('../controllers/movieController');
const upload = require('../middlewares/upload');

router.get('/', movieController.getAllMovies);
router.get('/:id', movieController.getOneMovie);


router.post('/addmovie', upload.single('image'), movieController.createMovie);

module.exports = router;