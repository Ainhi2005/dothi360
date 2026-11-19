import { createHmac } from 'node:crypto';
import { env } from '../../config/env';

// Bind an access token to the current password without exposing its Argon2 hash.
export const credentialVersion = (passwordHash: string) =>
  createHmac('sha256', env.JWT_ACCESS_SECRET).update(passwordHash).digest('hex');
