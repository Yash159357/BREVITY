const { default: mongoose } = require("mongoose");


const ReactionSchema = new mongoose.Schema({
  userid :{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  articleid:{
    type:String,
    required: true,
  },
  reactiontype: {
    type: String,
    enum: ["like", "dislike"],
    required: true,
  },
  createdat :{
    type: Date,
    default: Date.now,
  }
})

// to make sure one user have one reaction per article - compund index
ReactionSchema.index({userid:1,articleid:1},{unique:true})

module.exports = mongoose.model("Reaction", ReactionSchema);