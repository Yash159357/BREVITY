const User = require('../models/user');
const { deleteImage } = require('../services/cloudinary');
const { blacklistAllUserTokens, blacklistToken } = require('../services/jwt');
const { verifyGoogleToken } = require('../config/passport');

// Update user profile
const updateProfile = async (req, res) => {
    try {
        const userId = req.user._id;
        const updateData = {};

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Handle removeImage flag first (for full profile updates)
        if (req.body.removeImage === 'true') {
            if (user.profileImage?.publicId) {
                try {
                    await deleteImage(user.profileImage.publicId);
                } catch (error) {
                    console.error('Error deleting old profile image:', error);
                }
            }
            updateData.profileImage = undefined;
        }
        // Handle profile image update (only if not removing and file provided)
        else if (req.file) {
            // Delete old image if exists
            if (user.profileImage?.publicId) {
                try {
                    await deleteImage(user.profileImage.publicId);
                } catch (error) {
                    console.error('Error deleting old profile image:', error);
                }
            }

            updateData.profileImage = {
                url: req.file.path,
                publicId: req.file.filename
            };
        }

        // Only update displayName if it's provided and different
        if (req.body.displayName !== undefined && req.body.displayName.trim() !== user.displayName) {
            updateData.displayName = req.body.displayName.trim();
        }

        // Only update if there's data to update
        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        updateData.updatedAt = new Date();

        // Update user with only changed fields
        const updatedUser = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true, runValidators: true }
        ).select('-password -refreshTokens');

        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: { user: updatedUser }
        });

    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update profile',
            error: error.message
        });
    }
};

// Delete profile image
const deleteProfileImage = async (req, res) => {
    try {
        const userId = req.user._id;
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        if (!user.profileImage?.publicId) {
            return res.status(400).json({
                success: false,
                message: 'No profile image to delete'
            });
        }

        // Delete image from Cloudinary
        try {
            await deleteImage(user.profileImage.publicId);
        } catch (error) {
            console.error('Error deleting image from Cloudinary:', error);
        }

        // Remove image from user document
        user.profileImage = undefined;
        await user.save();

        res.json({
            success: true,
            message: 'Profile image deleted successfully'
        });

    } catch (error) {
        console.error('Delete profile image error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete profile image',
            error: error.message
        });
    }
};

//add delete account feature
const deleteUserAccount = async(req,res)=>{
    try{
        const userID = req.user._id;
        const {password, googleIdToken} = req.body;

        const user = await User.findById(userID).select('+password');
        if(!user){
            return res.status(404).json({
                success:false,
                message:"User not found"
            });
        }

        // Check if this is an OAuth-only account (no password hash)
        const isOAuthOnly = !user.password || user.password === '' || user.password.length < 20;

        if (isOAuthOnly) {
            // OAuth-only account - require OAuth re-authentication
            if (!googleIdToken) {
                return res.status(400).json({
                    success: false,
                    message: 'OAuth re-authentication required. Please provide googleIdToken.'
                });
            }

            try {
                // Verify Google token
                const googleUser = await verifyGoogleToken(googleIdToken);
                
                // Verify the Google account matches the user's email
                if (googleUser.email !== user.email) {
                    return res.status(401).json({
                        success: false,
                        message: 'OAuth account mismatch. Please authenticate with the correct Google account.'
                    });
                }
            } catch (error) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid Google authentication token'
                });
            }
        } else {
            // Regular account - require password verification
            if (!password) {
                return res.status(400).json({
                    success: false,
                    message: 'Password is required for account deletion'
                });
            }

            //verification of password
            const passwordMatch = await user.comparePassword(password);
            if(!passwordMatch){
                return res.status(401).json({
                    success:false,
                    message:'incorrect password'
                });
            }
        }

        // Blacklist all active tokens immediately
        try {
            await blacklistAllUserTokens(userID, 'account_deletion');
            
            // Also blacklist the current token being used for this request
            if (req.token) {
                await blacklistToken(req.token, userID, 'account_deletion');
            }
        } catch (error) {
            console.error('Error blacklisting tokens during account deletion:', error);
            // Continue with deletion even if token blacklisting fails
        }

        // Clear all refresh tokens from user document
        user.refreshTokens = [];
        await user.save();

        //delete profile image from cloudinary if exists
        if (user.profileImage?.publicId) {
            try {
                await deleteImage(user.profileImage.publicId);
            } catch (error) {
                console.error('Error deleting profile image during account deletion:', error);
            }
        }

        //delete profile
        await User.findByIdAndDelete(userID);
        
        res.status(200).json({
            success:true,
            message:`Account deletion successful for ${user.displayName}. All active sessions have been invalidated.`
        })

    }catch(err){
        console.error('Account deletion error:', err);
        res.status(500).json({
            success:false,
            message:'Failed to delete account, please retry',
            error:err.message
        })
    }
}

module.exports = {
    updateProfile,
    deleteProfileImage,
    deleteUserAccount
};