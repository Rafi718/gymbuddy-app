import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema/index';
import { dbConfig, env } from '../config/env';
import { logger } from '../utils/logger';

const pool = new Pool(dbConfig);

pool.on('error', (err: Error) => {
    logger.error({ err }, 'Unexpected PostgreSQL pool error');
});

export const db = drizzle(pool, { schema });
export type DB = typeof db;

export async function connectDB(): Promise<void> {
    const maxRetries = 10;
    for (let i = 1; i <= maxRetries; i++) {
        try {
            const client = await pool.connect();
            await client.query('SELECT 1');
            client.release();
            logger.info({ host: env.DB_HOST, database: env.DB_NAME }, '[DB] PostgreSQL connected successfully');
            return;
        } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            logger.warn({ attempt: i, maxRetries, err: msg }, '[DB] Connection attempt failed');
            if (i === maxRetries) {
                logger.error({ err }, '[DB] Failed to connect after max retries');
                throw err;
            }
            await new Promise((r) => setTimeout(r, 5000));
        }
    }
}

export async function closeDB(): Promise<void> {
    await pool.end();
    logger.info('[DB] PostgreSQL pool closed');
}

export { pool };
