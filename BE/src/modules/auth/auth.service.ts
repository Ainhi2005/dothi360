import { AppDataSource } from '../../database/data-source';
import { User } from '../users/user.entity';
import { RefreshToken } from './refresh-token.entity';
import * as argon2 from 'argon2';
import jwt, { SignOptions } from 'jsonwebtoken';
import crypto from 'crypto';
import { env } from '../../config/env';
import { ROLES } from '../../constants/roles';
import { assertUserIsActive, isRefreshTokenUsable } from './auth.policy';

export class AuthService {
  private userRepository = AppDataSource.getRepository(User);
  private tokenRepository = AppDataSource.getRepository(RefreshToken);

  async register(data: any) {
    const existingUser = await this.userRepository.findOne({ where: { email: data.email } });
    if (existingUser) {
      throw { statusCode: 409, message: 'Email đã được sử dụng' };
    }

    const hashedPassword = await argon2.hash(data.password);
    const newUser = this.userRepository.create({
      full_name: data.full_name,
      email: data.email,
      phone: data.phone,
      password_hash: hashedPassword,
      role: ROLES.CITIZEN,
    });

    await this.userRepository.save(newUser);
    const { password_hash, ...userWithoutPassword } = newUser;
    return userWithoutPassword;
  }

  async login(data: any) {
    const user = await this.userRepository.findOne({ where: { email: data.email } });
    if (!user) {
      throw { statusCode: 401, message: 'Email hoặc mật khẩu không đúng' };
    }
    assertUserIsActive(user);

    const isPasswordValid = await argon2.verify(user.password_hash, data.password);
    if (!isPasswordValid) {
      throw { statusCode: 401, message: 'Email hoặc mật khẩu không đúng' };
    }

    return this.generateTokens(user);
  }

  async refresh(refreshTokenStr: string) {
    const hashedToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    const tokenRecord = await this.tokenRepository.findOne({ where: { token_hash: hashedToken } });

    if (!tokenRecord || !isRefreshTokenUsable(tokenRecord)) {
      throw { statusCode: 401, message: 'Refresh token không hợp lệ hoặc đã hết hạn' };
    }

    const user = await this.userRepository.findOne({ where: { id: tokenRecord.user_id } });
    if (!user || !user.is_active) {
      throw { statusCode: 401, message: 'Người dùng không tồn tại hoặc bị khóa' };
    }

    const tokens = await this.generateTokens(user);
    tokenRecord.revoked_at = new Date();
    const replacementHash = crypto.createHash('sha256').update(tokens.refresh_token).digest('hex');
    const replacement = await this.tokenRepository.findOne({ where: { token_hash: replacementHash } });
    tokenRecord.replaced_by_id = replacement?.id ?? null;
    await this.tokenRepository.save(tokenRecord);
    return tokens;
  }

  async logout(refreshTokenStr: string) {
    const hashedToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    await this.tokenRepository.update({ token_hash: hashedToken }, { revoked_at: new Date() });
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user || !(await argon2.verify(user.password_hash, currentPassword))) {
      throw { statusCode: 400, message: 'Mật khẩu hiện tại không đúng' };
    }
    user.password_hash = await argon2.hash(newPassword);
    user.must_change_password = false;
    await this.userRepository.save(user);
    await this.tokenRepository.update({ user_id: userId }, { revoked_at: new Date() });
  }

  private async generateTokens(user: User) {
    const accessToken = jwt.sign(
      { id: user.id, role: user.role, department_id: user.department_id, must_change_password: user.must_change_password },
      env.JWT_ACCESS_SECRET,
      { expiresIn: env.JWT_ACCESS_EXPIRES_IN as SignOptions['expiresIn'] }
    );

    const refreshTokenStr = crypto.randomBytes(40).toString('hex');
    const hashedRefreshToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    
    // Expires in 7 days
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const newTokenRecord = this.tokenRepository.create({
      user_id: user.id,
      token_hash: hashedRefreshToken,
      expires_at: expiresAt,
    });
    await this.tokenRepository.save(newTokenRecord);

    const { password_hash, ...userProfile } = user;

    return {
      user: userProfile,
      access_token: accessToken,
      refresh_token: refreshTokenStr,
    };
  }
}
