// Script to create OAuth test users for testing account deletion
const mongoose = require('mongoose');
const User = require('./models/user');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/brevity', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

async function createOAuthUser() {
    try {
        // Create OAuth user (Google)
        const oauthUser = new User({
            displayName: 'OAuth Test User',
            email: 'oauth.test@example.com',
            oauthProviders: [{
                provider: 'google',
                providerId: 'google_123456789',
                createdAt: new Date()
            }],
            emailVerified: true,
            status: 'active'
        });

        await oauthUser.save();
        // console.log('OAuth user created:', oauthUser.email);
        // console.log('User ID:', oauthUser._id);
        // console.log('Is OAuth Only:', oauthUser.isOAuthOnly());

        // // Create local user for comparison
        // const localUser = new User({
        //     displayName: 'Local Test User',
        //     email: 'local.test@example.com',
        //     password: 'testpassword123',
        //     emailVerified: true,
        //     status: 'active'
        // });

        // await localUser.save();
        // console.log('Local user created:', localUser.email);
        // console.log('User ID:', localUser._id);
        // console.log('Is OAuth Only:', localUser.isOAuthOnly());

        process.exit(0);
    } catch (error) {
        console.error('Error creating test users:', error);
        process.exit(1);
    }
}

createOAuthUser();