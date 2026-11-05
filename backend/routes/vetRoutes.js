const express = require('express');
const router = express.Router();
const vetController = require('../controllers/vetController');

router.get('/', vetController.getAllVets);
router.get('/:id', vetController.getOneVet);
router.post('/', vetController.createVet);

module.exports = router;
