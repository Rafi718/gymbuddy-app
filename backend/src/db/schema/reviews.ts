import { pgTable, serial, integer, smallint, text, timestamp, index, uniqueIndex } from 'drizzle-orm/pg-core';
import { users } from './users';
import { sessions } from './sessions';

export const reviews = pgTable('reviews', {
    id: serial('id').primaryKey(),
    session_id: integer('session_id').notNull().references(() => sessions.id),
    member_id: integer('member_id').notNull().references(() => users.id),
    rating_score: smallint('rating_score').notNull(),
    comment: text('comment'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    sessionIdx: index('idx_reviews_session').on(table.session_id),
    memberIdx: index('idx_reviews_member').on(table.member_id),
    ratingIdx: index('idx_reviews_rating').on(table.rating_score),
    sessionMemberUniq: uniqueIndex('idx_reviews_session_member').on(table.session_id, table.member_id),
}));
