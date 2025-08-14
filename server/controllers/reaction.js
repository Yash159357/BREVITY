const Reaction = require("../models/reaction");

const toggleReaction = async (req, res) => {
  try {
    const { articleid, reactiontype } = req.body;

    const userid = req.user._id;;

    const existingReaction = await Reaction.findOne({ userid, articleid });

    if (!existingReaction) {
      await Reaction.create({ userid, articleid, reactiontype });
      return res.status(201).json({
        message: "Reaction created successfully",
      });
    }

    if (existingReaction.reactiontype === reactiontype) {
      await Reaction.deleteOne({ _id: existingReaction._id });
      return res.status(201).json({
        message: "Reaction deleted successfully",
      });
    }

    await Reaction.updateOne(
      { _id: existingReaction._id },
      { $set: { reactiontype } }
    );
    return res.status(201).json({
      message: "Reaction updated successfully",
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

module.exports = { toggleReaction };
