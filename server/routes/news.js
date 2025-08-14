const express = require('express');
const { getArticlesWithReactions } = require('../controllers/news');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/',authMiddleware,getArticlesWithReactions);

module.exports = router;