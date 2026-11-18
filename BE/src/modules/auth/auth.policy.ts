export function assertUserIsActive(user: { is_active: boolean }): void {
  if (!user.is_active) {
    throw { statusCode: 403, message: 'Tài khoản đã bị khóa' };
  }
}

export function isRefreshTokenUsable(
  token: { revoked_at: Date | null; expires_at: Date },
  now = new Date(),
): boolean {
  return token.revoked_at === null && token.expires_at > now;
}
