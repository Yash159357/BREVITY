// Script to delete test users created by create-oauth-user.js
const mongoose = require('mongoose');
const User = require('./models/user');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/brevity', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

async function deleteTestUsers() {
    try {
        // Delete OAuth test user
        const oauthResult = await User.deleteOne({ email: 'oauth.test@example.com' });
        console.log('OAuth user deleted:', oauthResult.deletedCount > 0 ? 'Success' : 'Not found');

        // Delete local test user
        const localResult = await User.deleteOne({ email: 'local.test@example.com' });
        console.log('Local user deleted:', localResult.deletedCount > 0 ? 'Success' : 'Not found');

        console.log('Test user cleanup completed');
        process.exit(0);
    } catch (error) {
        console.error('Error deleting test users:', error);
        process.exit(1);
    }
}

deleteTestUsers();