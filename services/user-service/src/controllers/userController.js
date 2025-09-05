const { query } = require('../utils/database');
const { validateProfile } = require('../utils/validation');
const { logger } = require('../utils/logger');

const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await query('SELECT * FROM user_profiles WHERE user_id = $1', [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { first_name, last_name, phone, avatar_url, bio } = req.body;
    
    const validation = validateProfile(req.body);
    if (!validation.isValid) {
      return res.status(400).json({ errors: validation.errors });
    }
    
    const result = await query(
      `INSERT INTO user_profiles (user_id, first_name, last_name, phone, avatar_url, bio, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id) 
       DO UPDATE SET 
         first_name = EXCLUDED.first_name,
         last_name = EXCLUDED.last_name,
         phone = EXCLUDED.phone,
         avatar_url = EXCLUDED.avatar_url,
         bio = EXCLUDED.bio,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [userId, first_name, last_name, phone, avatar_url, bio]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Update profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { getProfile, updateProfile };