import { pgTable, serial, integer, numeric, varchar, text, timestamp, index } from 'drizzle-orm/pg-core';
import { users } from './users';

export const bodyProgress = pgTable('body_progress', {
    id: serial('id').primaryKey(),
    member_id: integer('member_id').notNull().references(() => users.id),
    berat_badan: numeric('berat_badan', { precision: 5, scale: 2 }),
    tinggi_badan: numeric('tinggi_badan', { precision: 5, scale: 2 }),
    bmi: numeric('bmi', { precision: 4, scale: 2 }),
    body_fat: numeric('body_fat', { precision: 4, scale: 1 }),
    target_berat: numeric('target_berat', { precision: 5, scale: 2 }),
    foto_before: varchar('foto_before', { length: 255 }),
    foto_after: varchar('foto_after', { length: 255 }),
    catatan: text('catatan'),
    recorded_at: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
    memberIdx: index('idx_body_progress_member').on(table.member_id),
}));
