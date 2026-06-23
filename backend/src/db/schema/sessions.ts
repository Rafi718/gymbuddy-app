import { pgTable, serial, varchar, text, timestamp, numeric, integer, pgEnum, index } from 'drizzle-orm/pg-core';
import { users } from './users';

export const sessionStatusEnum = pgEnum('session_status', ['scheduled', 'ongoing', 'completed', 'cancelled']);

export const sessions = pgTable('sessions', {
    id: serial('id').primaryKey(),
    title: varchar('title', { length: 100 }).notNull(),
    description: text('description'),
    trainer_id: integer('trainer_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    start_time: timestamp('start_time', { withTimezone: true }).notNull(),
    end_time: timestamp('end_time', { withTimezone: true }),
    price: numeric('price', { precision: 10, scale: 2 }).default('0.00').notNull(),
    status: sessionStatusEnum('status').notNull().default('scheduled'),
    max_participants: integer('max_participants').default(1).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    trainerIdx: index('idx_sessions_trainer').on(table.trainer_id),
    startTimeIdx: index('idx_sessions_start_time').on(table.start_time),
    trainerStartIdx: index('idx_sessions_trainer_start').on(table.trainer_id, table.start_time),
}));
