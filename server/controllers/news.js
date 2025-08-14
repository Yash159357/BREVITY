const axios = require("axios");

const Reaction = require("../models/reaction");

const NEWS_API_KEY = process.env.NEWS_API_KEY;

const getArticlesWithReactions = async (req, res) => {
  const _topHeadlinesUrl = "https://newsapi.org/v2/top-headlines";
  const _everythingUrl = "https://newsapi.org/v2/everything";

  const { category, q, page = 1, pageSize = 10, sortedBy } = req.query;
  const userId =  req.user._id;

  let url;

  if (category) {
    url = `${_topHeadlinesUrl}?country=us&category=${category}&page=${page}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  } else if (q && sortedBy) {
    url = `${_everythingUrl}?q=${q}&language=en&sortBy=${sortedBy}&page=${page}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  } else {
    url = `${_topHeadlinesUrl}?country=us&page=${page}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  }

  try {
    const response = await axios.get(url);
    const articles = response.data.articles;
    const articleIds = articles.map((a) => a.url);

    // Aggregate likes & dislikes counts together
    const reactionCounts = await Reaction.aggregate([
      { $match: { articleid: { $in: articleIds } } },
      {
        $group: {
          _id: { articleid: "$articleid", reactiontype: "$reactiontype" },
          count: { $sum: 1 },
        },
      },
    ]);

    // Map counts by article and type
    const likeCountMap = {};
    const dislikeCountMap = {};
    reactionCounts.forEach((r) => {
      if (r._id.reactiontype === "like") {
        likeCountMap[r._id.articleid] = r.count;
      } else if (r._id.reactiontype === "dislike") {
        dislikeCountMap[r._id.articleid] = r.count;
      }
    });

    // Find which ones the user liked/disliked
    const likedByMe = await Reaction.find({
      articleid: { $in: articleIds },
      userid: userId,
      reactiontype: "like",
    });

    const dislikedByMe = await Reaction.find({
      articleid: { $in: articleIds },
      userid: userId,
      reactiontype: "dislike",
    });

    const likedSet = new Set(likedByMe.map((r) => r.articleid));
    const dislikedSet = new Set(dislikedByMe.map((r) => r.articleid));

    // Merge into articles
    const modifiedArticles = articles.map((article) => ({
      ...article,
      isLikedByMe: likedSet.has(article.url),
      likes: likeCountMap[article.url] || 0,
      isDislikedByMe: dislikedSet.has(article.url),
      dislikes: dislikeCountMap[article.url] || 0,
    }));

    return res.status(200).json(modifiedArticles);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getArticlesWithReactions,
};
