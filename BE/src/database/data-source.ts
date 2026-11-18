/** Khởi tạo TypeORM DataSource, khai báo entities và migrations dùng chung. */
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { dbConfig } from '../config/database';

// Khởi tạo instance của TypeORM
export const AppDataSource = new DataSource(dbConfig);
