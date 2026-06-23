import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

// ── PostgreSQL connection config ──────────────────────────────
// Supports DATABASE_URL (e.g. postgres://user:pass@host:port/db)
// or individual PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE env vars.
const config = process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
        max: 10,
    }
    : {
        host: process.env.PGHOST || process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.PGPORT || process.env.DB_PORT || '5432'),
        user: process.env.PGUSER || process.env.DB_USER || 'postgres',
        password: process.env.PGPASSWORD || process.env.DB_PASSWORD || '',
        database: process.env.PGDATABASE || process.env.DB_NAME || 'gymbuddy',
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
        max: 10,
    };

console.log('[DB] Connecting to PostgreSQL:', config.host || config.connectionString);

const pool = new Pool(config);

let dbConnected = false;
let lastDbError = null;

export const isDBConnected = () => dbConnected;
export const getLastDbError = () => lastDbError;

export const connectDB = async () => {
    await attemptConnection();
};

async function attemptConnection(retries = 10, delay = 5000) {
    console.log('[DB] Connecting to database...');
    for (let i = 0; i < retries; i++) {
        try {
            const client = await pool.connect();
            await client.query('SELECT 1');
            client.release();
            dbConnected = true;
            console.log('Database connected successfully');
            return;
        } catch (error) {
            lastDbError = error.message;
            console.log('[DB] Attempt ' + (i + 1) + '/' + retries + ' failed:', error.message);
            if (i < retries - 1) {
                console.log('[DB] Retrying in ' + (delay / 1000) + 's...');
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }
    console.error('[DB] All attempts failed. Will retry in 60s...');
    setTimeout(attemptConnection, 60000, retries, delay);
}

// ── Query wrapper ─────────────────────────────────────────────
// Converts MySQL-style ? placeholders to PostgreSQL $n placeholders,
// quotes the reserved "user" table name, auto-adds RETURNING id to
// INSERT queries, and normalises the return shape so controllers
// don't need to change their query syntax.

function convertQuery(text) {
    // 1. Quote the "user" table — reserved keyword in PostgreSQL
    text = text.replace(/\bFROM\s+user\b/gi, 'FROM "user"');
    text = text.replace(/\bJOIN\s+user\b/gi, 'JOIN "user"');
    text = text.replace(/\bINTO\s+user\b/gi, 'INTO "user"');
    text = text.replace(/\bUPDATE\s+user\b/gi, 'UPDATE "user"');

    // 2. Convert ? placeholders → $n
    let idx = 0;
    text = text.replace(/\?/g, () => `$${++idx}`);

    // 3. Auto-add RETURNING id to INSERT (if not already present)
    if (/^\s*INSERT\b/i.test(text) && !/\bRETURNING\b/i.test(text)) {
        text = text.replace(/;\s*$/, '');
        text += ' RETURNING id';
    }

    return text;
}

// Normalise pg result into a shape that mimics the old mariadb driver:
//  - SELECT  → array of rows
//  - INSERT  → { insertId, affectedRows }
//  - UPDATE/DELETE → { affectedRows }
function normaliseResult(result) {
    if (result.command === 'INSERT') {
        return {
            insertId: result.rows[0]?.id ?? null,
            affectedRows: result.rowCount,
        };
    }
    if (result.command === 'UPDATE' || result.command === 'DELETE') {
        return { affectedRows: result.rowCount };
    }
    // SELECT → return rows array (like mariadb)
    return result.rows;
}

// Wrapped pool that mimics the old mariadb pool API
const wrappedPool = {
    async query(text, params = []) {
        const converted = convertQuery(text);
        const result = await pool.query(converted, params);
        return normaliseResult(result);
    },

    // Alias — old code calls both getConnection() and connect()
    async getConnection() {
        return this.connect();
    },

    async connect() {
        const client = await pool.connect();
        const wrappedClient = {
            async query(text, params = []) {
                const converted = convertQuery(text);
                const result = await client.query(converted, params);
                return normaliseResult(result);
            },
            beginTransaction: () => client.query('BEGIN'),
            commit: () => client.query('COMMIT'),
            rollback: () => client.query('ROLLBACK'),
            release: () => client.release(),
        };
        return wrappedClient;
    },
};

export const getDBPool = () => {
    return wrappedPool;
};

export default pool;
