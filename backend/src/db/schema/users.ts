import { pgTable, serial, varchar, text, date, char, timestamp, boolean, pgEnum, index } from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', ['customer', 'trainer', 'admin']);

export const users = pgTable('users', {
    id: serial('id').primaryKey(),
    nama: varchar('nama', { length: 100 }).notNull(),
    email: varchar('email', { length: 255 }).notNull().unique(),
    password: varchar('password', { length: 255 }).notNull(),
    role: userRoleEnum('role').notNull().default('customer'),
    jenis_kelamin: char('jenis_kelamin', { length: 1 }),
    no_telp: varchar('no_telp', { length: 20 }),
    tanggal_lahir: date('tanggal_lahir'),
    foto: varchar('foto', { length: 255 }),
    bio: text('bio'),
    propinsi: varchar('propinsi', { length: 45 }).default(''),
    kota: varchar('kota', { length: 45 }).default(''),
    spesialisasi: varchar('spesialisasi', { length: 100 }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    roleIdx: index('idx_users_role').on(table.role),
    kotaIdx: index('idx_users_kota').on(table.kota),
}));
