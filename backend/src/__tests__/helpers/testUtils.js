const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');

const uploadsDirectory = path.resolve(__dirname, '../../../uploads');

function authHeader(payload) {
  const token = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret');
  return 'Bearer ' + token;
}

function adminAuthHeader() {
  return authHeader({ id: 1, email: 'admin@buildtrack.com', role: 'admin' });
}

function staffAuthHeader(overrides = {}) {
  return authHeader({ id: overrides.id || 2, email: overrides.email || 'staff@buildtrack.com', role: 'staff' });
}

function cleanupUploads() {
  if (!fs.existsSync(uploadsDirectory)) {
    return;
  }

  for (const file of fs.readdirSync(uploadsDirectory)) {
    if (file !== '.gitkeep') {
      fs.unlinkSync(path.join(uploadsDirectory, file));
    }
  }
}

module.exports = {
  adminAuthHeader,
  staffAuthHeader,
  cleanupUploads,
  uploadsDirectory
};
