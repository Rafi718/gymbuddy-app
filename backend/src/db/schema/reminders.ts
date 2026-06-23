import { pgTable, serial, integer, varchar, time, timestamp, boolean, pgEnum, index } from 'drizzle-orm/pg-core';
import { users } from './users';

export const reminderTipeEnum = pgEnum('reminder_tipe', ['latihan', 'minum', 'makan', 'tidur', 'custom']);

export const reminders = pgTable('reminders', {
    id: serial('id').primaryKey(),
    user_id: integer('user_id').notNull().references(() => users.id),
    judul: varchar('judul', { length: 200 }).notNull(),
    tipe: reminderTipeEnum('tipe').default('latihan').notNull(),
    waktu: time('waktu'),
    hari: varchar('hari', { length: 50 }),
    is_active: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
    userIdx: index('idx_reminders_user').on(table.user_id),
}));
