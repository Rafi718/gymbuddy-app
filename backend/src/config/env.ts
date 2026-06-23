import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
    DATABASE_URL: z.string().optional(),
    DB_HOST: z.string().default('localhost'),
    DB_PORT: z.coerce.number().default(5432),
    DB_USER: z.string().default('postgres'),
    DB_PASSWORD: z.string().default(''),
    DB_NAME: z.string().default('gymbuddy'),
    DB_SSL: z.string().optional(),

    JWT_SECRET: z.string().min(1, 'JWT_SECRET wajib diisi'),

    PORT: z.coerce.number().default(5000),
    NODE_ENV: z.enum(['development', 'production', 'test']).default('production'),

    FRONTEND_URL: z.string().default('http://localhost:5173'),

    MIDTRANS_SERVER_KEY: z.string().default(''),
    MIDTRANS_CLIENT_KEY: z.string().default(''),
    MIDTRANS_IS_PRODUCTION: z.string().default('false'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
    console.error('[ENV] Invalid environment variables:');
    console.error(parsed.error.format());
    process.exit(1);
}

export const env = parsed.data;

export const dbConfig = env.DATABASE_URL
    ? {
          connectionString: env.DATABASE_URL,
          ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
          max: 10,
      }
    : {
          host: env.DB_HOST,
          port: env.DB_PORT,
          user: env.DB_USER,
          password: env.DB_PASSWORD,
          database: env.DB_NAME,
          ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
          max: 10,
      };
