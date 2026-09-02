import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

/**
 * Used by TypeORM CLI for migrations.
 * The app itself uses TypeOrmModule.forRootAsync in app.module.ts.
 */
export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'staynest',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'staynest',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/database/migrations/*.ts'],
  logging: ['error', 'warn', 'migration'],
});
