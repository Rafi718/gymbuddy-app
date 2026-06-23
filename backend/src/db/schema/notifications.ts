import { pgTable, serial, integer, varchar, text, timestamp, boolean, pgEnum, index } from 'drizzle-orm/pg-core';
import { users } from './users';

export const notificationTypeEnum = pgEnum('notification_type', ['booking', 'payment', 'progress', 'promo', 'system']);

export const notifications = pgTable('notifications', {
    id: serial('id').primaryKey(),
    user_id: integer('user_id').notNull().references(() => users.id),
    title: varchar('title', { length: 200 }).notNull(),
    message: text('message').notNull(),
    type: notificationTypeEnum('type').default('system').notNull(),
    is_read: boolean('is_read').default(false).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
    userIdx: index('idx_notifications_user').on(table.user_id),
    isReadIdx: index('idx_notifications_is_read').on(table.is_read),
}));
