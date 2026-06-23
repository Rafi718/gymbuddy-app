import { pgTable, serial, integer, varchar, text, timestamp, numeric, uniqueIndex, index, pgEnum } from 'drizzle-orm/pg-core';
import { users } from './users';
import { sessions } from './sessions';

export const bookingStatusEnum = pgEnum('booking_status', ['pending', 'confirmed', 'completed', 'cancelled']);
export const paymentStatusEnum = pgEnum('payment_status', ['pending', 'settlement', 'cancel', 'expire']);

export const bookings = pgTable('bookings', {
    id: serial('id').primaryKey(),
    session_id: integer('session_id').notNull().references(() => sessions.id),
    member_id: integer('member_id').notNull().references(() => users.id),
    status: bookingStatusEnum('status').notNull().default('pending'),
    payment_status: paymentStatusEnum('payment_status').default('pending').notNull(),
    payment_method: varchar('payment_method', { length: 50 }),
    payment_amount: numeric('payment_amount', { precision: 10, scale: 2 }).default('0.00').notNull(),
    payment_date: timestamp('payment_date', { withTimezone: true }),
    midtrans_transaction_id: varchar('midtrans_transaction_id', { length: 100 }),
    midtrans_order_id: varchar('midtrans_order_id', { length: 100 }),
    midtrans_token: text('midtrans_token'),
    catatan: text('catatan'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    sessionMemberUniq: uniqueIndex('idx_bookings_session_member').on(table.session_id, table.member_id),
    memberIdx: index('idx_bookings_member').on(table.member_id),
    statusIdx: index('idx_bookings_status').on(table.status),
    paymentStatusIdx: index('idx_bookings_payment_status').on(table.payment_status),
}));
