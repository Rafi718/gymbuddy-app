import { pgTable, serial, integer, varchar, text, date, timestamp, boolean, pgEnum, index } from 'drizzle-orm/pg-core';
import { users } from './users';

export const dietTipeEnum = pgEnum('diet_tipe', ['bulking', 'cutting', 'maintenance']);

export const dietPrograms = pgTable('diet_programs', {
    id: serial('id').primaryKey(),
    user_id: integer('user_id').notNull().references(() => users.id),
    tipe: dietTipeEnum('tipe').notNull(),
    target_kalori: integer('target_kalori'),
    target_protein: integer('target_protein'),
    target_karbohidrat: integer('target_karbohidrat'),
    target_lemak: integer('target_lemak'),
    tanggal_mulai: date('tanggal_mulai'),
    tanggal_selesai: date('tanggal_selesai'),
    is_active: boolean('is_active').default(true).notNull(),
    catatan: text('catatan'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    userIdx: index('idx_diet_programs_user').on(table.user_id),
}));
