import { DataSourceOptions } from 'typeorm';
type PostgresOptions = Extract<DataSourceOptions, { type: 'postgres' }>;

export type DatabaseEnvironment = {
  DATABASE_URL?: string;
  DB_HOST?: string;
  DB_PORT?: number;
  DB_USER?: string;
  DB_PASSWORD?: string;
  DB_NAME?: string;
  DB_SSL?: 'true' | 'false';
};

/** Keep local connections unchanged; cloud TLS always verifies the server certificate. */
export function databaseConnection(config: DatabaseEnvironment): Partial<PostgresOptions> {
  const sslEnabled = config.DB_SSL === 'true' || (config.DB_SSL === undefined && Boolean(config.DATABASE_URL));
  const ssl = sslEnabled ? { rejectUnauthorized: true } : false;
  if (config.DATABASE_URL) {
    const url = new URL(config.DATABASE_URL);
    if (!['postgres:', 'postgresql:'].includes(url.protocol)) throw new Error('DATABASE_URL phải dùng postgres:// hoặc postgresql://');
    // pg otherwise replaces the explicit ssl object with the URL's weaker sslmode settings.
    for (const key of ['sslmode', 'sslcert', 'sslkey', 'sslrootcert', 'uselibpqcompat']) url.searchParams.delete(key);
    return { url: url.toString(), ssl };
  }
  return { host: config.DB_HOST, port: config.DB_PORT ?? 5432,
    username: config.DB_USER, password: config.DB_PASSWORD, database: config.DB_NAME, ssl };
}
