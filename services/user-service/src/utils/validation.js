const validator = require('validator');

const validateProfile = (data) => {
  const errors = [];

  if (data.first_name && !validator.isLength(data.first_name, { min: 1, max: 50 })) {
    errors.push('First name must be 1-50 characters');
  }

  if (data.last_name && !validator.isLength(data.last_name, { min: 1, max: 50 })) {
    errors.push('Last name must be 1-50 characters');
  }

  if (data.phone && !validator.isMobilePhone(data.phone)) {
    errors.push('Invalid phone number format');
  }

  if (data.avatar_url && !validator.isURL(data.avatar_url)) {
    errors.push('Invalid avatar URL');
  }

  if (data.bio && !validator.isLength(data.bio, { max: 500 })) {
    errors.push('Bio must be less than 500 characters');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

module.exports = { validateProfile };