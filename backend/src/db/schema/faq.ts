import { pgTable, serial, varchar, text, integer, timestamp, boolean } from 'drizzle-orm/pg-core';

export const faq = pgTable('faq', {
    id: serial('id').primaryKey(),
    pertanyaan: text('pertanyaan').notNull(),
    jawaban: text('jawaban').notNull(),
    kategori: varchar('kategori', { length: 50 }).default('umum').notNull(),
    urutan: integer('urutan').default(0).notNull(),
    is_active: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
