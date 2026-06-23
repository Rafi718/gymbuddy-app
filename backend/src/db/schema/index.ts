import { relations } from 'drizzle-orm';

// Tables
export { users, userRoleEnum } from './users';
export { sessions, sessionStatusEnum } from './sessions';
export { bookings, bookingStatusEnum, paymentStatusEnum } from './bookings';
export { reviews } from './reviews';
export { progress } from './progress';
export { bodyProgress } from './bodyProgress';
export { notifications, notificationTypeEnum } from './notifications';
export { articles, articleKategoriEnum } from './articles';
export { promo, promoTipeEnum } from './promo';
export { banners } from './banners';
export { faq } from './faq';
export { reminders, reminderTipeEnum } from './reminders';
export { dietPrograms, dietTipeEnum } from './dietPrograms';

// Import for relations
import { users } from './users';
import { sessions } from './sessions';
import { bookings } from './bookings';
import { reviews } from './reviews';
import { progress } from './progress';
import { bodyProgress } from './bodyProgress';
import { notifications } from './notifications';
import { articles } from './articles';
import { reminders } from './reminders';
import { dietPrograms } from './dietPrograms';

// Relations — centralized here to avoid circular imports
export const usersRelations = relations(users, ({ many }) => ({
    sessions: many(sessions),
    bookings: many(bookings),
    reviews: many(reviews),
    progress: many(progress),
    bodyProgress: many(bodyProgress),
    notifications: many(notifications),
    reminders: many(reminders),
    dietPrograms: many(dietPrograms),
    articles: many(articles),
}));

export const sessionsRelations = relations(sessions, ({ one, many }) => ({
    trainer: one(users, { fields: [sessions.trainer_id], references: [users.id] }),
    bookings: many(bookings),
    reviews: many(reviews),
}));

export const bookingsRelations = relations(bookings, ({ one, many }) => ({
    session: one(sessions, { fields: [bookings.session_id], references: [sessions.id] }),
    member: one(users, { fields: [bookings.member_id], references: [users.id] }),
    progress: many(progress),
}));

export const reviewsRelations = relations(reviews, ({ one }) => ({
    session: one(sessions, { fields: [reviews.session_id], references: [sessions.id] }),
    member: one(users, { fields: [reviews.member_id], references: [users.id] }),
}));

export const progressRelations = relations(progress, ({ one }) => ({
    member: one(users, { fields: [progress.member_id], references: [users.id] }),
    booking: one(bookings, { fields: [progress.booking_id], references: [bookings.id] }),
}));

export const bodyProgressRelations = relations(bodyProgress, ({ one }) => ({
    member: one(users, { fields: [bodyProgress.member_id], references: [users.id] }),
}));

export const notificationsRelations = relations(notifications, ({ one }) => ({
    user: one(users, { fields: [notifications.user_id], references: [users.id] }),
}));

export const articlesRelations = relations(articles, ({ one }) => ({
    author: one(users, { fields: [articles.author_id], references: [users.id] }),
}));

export const remindersRelations = relations(reminders, ({ one }) => ({
    user: one(users, { fields: [reminders.user_id], references: [users.id] }),
}));

export const dietProgramsRelations = relations(dietPrograms, ({ one }) => ({
    user: one(users, { fields: [dietPrograms.user_id], references: [users.id] }),
}));
