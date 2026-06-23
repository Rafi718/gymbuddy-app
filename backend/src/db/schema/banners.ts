import { pgTable, serial, varchar, text, integer, timestamp, boolean } from 'drizzle-orm/pg-core';

export const banners = pgTable('banners', {
    id: serial('id').primaryKey(),
    judul: varchar('judul', { length: 200 }),
    deskripsi: text('deskripsi'),
    gambar: varchar('gambar', { length: 255 }).notNull(),
    link: varchar('link', { length: 255 }),
    urutan: integer('urutan').default(0).notNull(),
    is_active: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
