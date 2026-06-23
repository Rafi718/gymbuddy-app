import { pgTable, serial, varchar, text, timestamp, boolean, integer, pgEnum, index, uniqueIndex } from 'drizzle-orm/pg-core';
import { users } from './users';

export const articleKategoriEnum = pgEnum('article_kategori', ['Diet', 'Bulking', 'Cutting', 'Workout', 'Motivasi']);

export const articles = pgTable('articles', {
    id: serial('id').primaryKey(),
    title: varchar('title', { length: 200 }).notNull(),
    slug: varchar('slug', { length: 200 }).notNull().unique(),
    content: text('content'),
    excerpt: text('excerpt'),
    kategori: articleKategoriEnum('kategori').default('Workout').notNull(),
    author_id: integer('author_id').references(() => users.id),
    foto: varchar('foto', { length: 255 }),
    is_published: boolean('is_published').default(false).notNull(),
    published_at: timestamp('published_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }),
}, (table) => ({
    kategoriIdx: index('idx_articles_kategori').on(table.kategori),
    authorIdx: index('idx_articles_author').on(table.author_id),
}));
