const buckets = new Map();

function createRateLimiter(options = {}) {
  const windowMs = options.windowMs || 15 * 60 * 1000;
  const maxRequests = options.maxRequests || 200;

  return function rateLimit(req, res, next) {
    const now = Date.now();
    const key = `${req.ip}:${req.method}:${req.baseUrl || ''}${req.path}`;
    const current = buckets.get(key);

    if (!current || current.expiresAt <= now) {
      buckets.set(key, { count: 1, expiresAt: now + windowMs });
      return next();
    }

    if (current.count >= maxRequests) {
      return res.status(429).json({ message: 'Too many requests, please try again later' });
    }

    current.count += 1;
    return next();
  };
}

function resetRateLimiter() {
  buckets.clear();
}

module.exports = {
  createRateLimiter,
  resetRateLimiter
};
