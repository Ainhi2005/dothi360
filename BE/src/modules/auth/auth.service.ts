import { AppDataSource } from '../../database/data-source';
import { User } from '../users/user.entity';
import { RefreshToken } from './refresh-token.entity';
import * as argon2 from 'argon2';
import jwt, { SignOptions } from 'jsonwebtoken';
import crypto from 'crypto';
import { env } from '../../config/env';
import { ROLES } from '../../constants/roles';
import { assertUserIsActive, isRefreshTokenUsable } from './auth.policy';
import { credentialVersion } from './credential-version';
import { EntityManager } from 'typeorm';

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
    return AppDataSource.transaction(async manager => {
      const user = await manager.getRepository(User).findOne({ where: { email: data.email }, lock: { mode: 'pessimistic_write' } });
      if (!user) {
        throw { statusCode: 401, message: 'Email hoặc mật khẩu không đúng' };
      }
      assertUserIsActive(user);

      const isPasswordValid = await argon2.verify(user.password_hash, data.password);
      if (!isPasswordValid) {
        throw { statusCode: 401, message: 'Email hoặc mật khẩu không đúng' };
      }

      return this.generateTokens(user, manager);
    });
  }

  async refresh(refreshTokenStr: string) {
    const hashedToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    const tokenRecord = await this.tokenRepository.findOne({ where: { token_hash: hashedToken } });

    if (!tokenRecord || !isRefreshTokenUsable(tokenRecord)) {
      throw { statusCode: 401, message: 'Refresh token không hợp lệ hoặc đã hết hạn' };
    }

    return AppDataSource.transaction(async manager => {
      const user = await manager.getRepository(User).findOne({ where: { id: tokenRecord.user_id }, lock: { mode: 'pessimistic_write' } });
      if (!user || !user.is_active) {
        throw { statusCode: 401, message: 'Người dùng không tồn tại hoặc bị khóa' };
      }

      const tokensRepo = manager.getRepository(RefreshToken);
      const lockedToken = await tokensRepo.findOne({ where: { id: tokenRecord.id }, lock: { mode: 'pessimistic_write' } });
      if (!lockedToken || !isRefreshTokenUsable(lockedToken)) throw { statusCode: 401, message: 'Refresh token không hợp lệ hoặc đã hết hạn' };
      const tokens = await this.generateTokens(user, manager);
      lockedToken.revoked_at = new Date();
      const replacementHash = crypto.createHash('sha256').update(tokens.refresh_token).digest('hex');
      const replacement = await tokensRepo.findOne({ where: { token_hash: replacementHash } });
      lockedToken.replaced_by_id = replacement?.id ?? null;
      await tokensRepo.save(lockedToken);
      return tokens;
    });
  }

  async logout(refreshTokenStr: string) {
    const hashedToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    await this.tokenRepository.update({ token_hash: hashedToken }, { revoked_at: new Date() });
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    await AppDataSource.transaction(async manager => {
      const users = manager.getRepository(User);
      const user = await users.findOne({ where: { id: userId }, lock: { mode: 'pessimistic_write' } });
      if (!user || !(await argon2.verify(user.password_hash, currentPassword))) {
        throw { statusCode: 400, message: 'Mật khẩu hiện tại không đúng' };
      }
      user.password_hash = await argon2.hash(newPassword);
      user.must_change_password = false;
      await users.save(user);
      await manager.getRepository(RefreshToken).update({ user_id: userId }, { revoked_at: new Date() });
    });
  }

  private async generateTokens(user: User, manager: EntityManager = AppDataSource.manager) {
    const accessToken = jwt.sign(
      { id: user.id, role: user.role, department_id: user.department_id, must_change_password: user.must_change_password, credential_version: credentialVersion(user.password_hash) },
      env.JWT_ACCESS_SECRET,
      { expiresIn: env.JWT_ACCESS_EXPIRES_IN as SignOptions['expiresIn'] }
    );

    const refreshTokenStr = crypto.randomBytes(40).toString('hex');
    const hashedRefreshToken = crypto.createHash('sha256').update(refreshTokenStr).digest('hex');
    
    // Expires in 7 days
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const tokensRepo = manager.getRepository(RefreshToken);
    const newTokenRecord = tokensRepo.create({
      user_id: user.id,
      token_hash: hashedRefreshToken,
      expires_at: expiresAt,
    });
    await tokensRepo.save(newTokenRecord);

    const { password_hash, ...userProfile } = user;

    return {
      user: userProfile,
      access_token: accessToken,
      refresh_token: refreshTokenStr,
    };
  }
}
