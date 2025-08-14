// article.js
const mongoose = require("mongoose");

const articleSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true, maxlength: 100 },
  description: { type: String, required: true, trim: true, maxlength: 500 },
  url: { type: String, required: true, trim: true, maxlength: 200 },
  urlToImage: { type: String, required: true, trim: true, maxlength: 200 },
  publishedAt: { type: Date, required: true },
  sourceName: { type: String, required: true, trim: true },
  author: { type: String, required: true, trim: true, maxlength: 100 },
  content: { type: String, required: true },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
});

articleSchema.index({ userId: 1, url: 1 }, { unique: true });

articleSchema.virtual("timeAgo").get(function () {
  const now = new Date();
  const diffInSeconds = Math.floor((now - this.publishedAt) / 1000);
  if (diffInSeconds < 60) return `${diffInSeconds} seconds ago`;
  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) return `${diffInMinutes} minutes ago`;
  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) return `${diffInHours} hours ago`;
  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 7) return `${diffInDays} days ago`;
  return `${Math.floor(diffInDays / 7)} weeks ago`;
});

articleSchema.pre("save", function (next) {
  if (this.isNew) {
    this.publishedAt = new Date(this.publishedAt);
  }
  next();
});

module.exports = mongoose.model("Article", articleSchema);

