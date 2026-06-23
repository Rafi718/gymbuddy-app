import { pgTable, serial, integer, varchar, text, timestamp, index } from 'drizzle-orm/pg-core';
import { users } from './users';
import { bookings } from './bookings';

export const progress = pgTable('progress', {
    id: serial('id').primaryKey(),
    member_id: integer('member_id').notNull().references(() => users.id),
    booking_id: integer('booking_id').references(() => bookings.id),
    activity: varchar('activity', { length: 100 }).notNull(),
    duration: integer('duration').notNull(),
    note: text('note'),
    recorded_at: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
    memberIdx: index('idx_progress_member').on(table.member_id),
    bookingIdx: index('idx_progress_booking').on(table.booking_id),
}));
