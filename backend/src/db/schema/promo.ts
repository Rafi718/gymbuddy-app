import { pgTable, serial, varchar, text, numeric, integer, timestamp, boolean, pgEnum, uniqueIndex } from 'drizzle-orm/pg-core';

export const promoTipeEnum = pgEnum('promo_tipe', ['persen', 'nominal']);

export const promo = pgTable('promo', {
    id: serial('id').primaryKey(),
    kode: varchar('kode', { length: 50 }).notNull().unique(),
    judul: varchar('judul', { length: 200 }).notNull(),
    deskripsi: text('deskripsi'),
    tipe: promoTipeEnum('tipe').default('nominal').notNull(),
    nilai: numeric('nilai', { precision: 10, scale: 2 }).notNull(),
    min_booking: integer('min_booking').default(1).notNull(),
    maks_diskon: numeric('maks_diskon', { precision: 10, scale: 2 }),
    kuota: integer('kuota'),
    terpakai: integer('terpakai').default(0).notNull(),
    tanggal_mulai: timestamp('tanggal_mulai', { withTimezone: true }),
    tanggal_selesai: timestamp('tanggal_selesai', { withTimezone: true }),
    is_active: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
