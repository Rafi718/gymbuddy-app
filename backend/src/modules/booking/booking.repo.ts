import { eq, and, sql, desc, ne } from 'drizzle-orm';
import { db } from '../../db/client';
import { bookings, sessions, users } from '../../db/schema';

export async function findAll(opts: {
    page: number;
    limit: number;
    status?: string;
    payment_status?: string;
}) {
    const conditions = [];
    if (opts.status) conditions.push(eq(bookings.status, opts.status as any));
    if (opts.payment_status) conditions.push(eq(bookings.payment_status, opts.payment_status as any));
    const where = conditions.length > 0 ? and(...conditions) : undefined;

    const rows = await db.select({
        id: bookings.id,
        session_id: bookings.session_id,
        member_id: bookings.member_id,
        status: bookings.status,
        payment_status: bookings.payment_status,
        payment_amount: bookings.payment_amount,
        catatan: bookings.catatan,
        createdAt: bookings.createdAt,
        updatedAt: bookings.updatedAt,
        session_title: sessions.title,
        session_start_time: sessions.start_time,
        session_end_time: sessions.end_time,
        session_price: sessions.price,
        member_nama: users.nama,
        member_email: users.email,
    })
    .from(bookings)
    .leftJoin(sessions, eq(bookings.session_id, sessions.id))
    .leftJoin(users, eq(bookings.member_id, users.id))
    .where(where)
    .orderBy(desc(bookings.createdAt))
    .limit(opts.limit)
    .offset((opts.page - 1) * opts.limit);

    const countResult = await db.select({ count: sql<number>`count(*)` })
    .from(bookings)
    .where(where);
    const total = Number(countResult[0].count);

    return { rows, total };
}

export async function findById(id: number) {
    const rows = await db.select({
        id: bookings.id,
        session_id: bookings.session_id,
        member_id: bookings.member_id,
        status: bookings.status,
        payment_status: bookings.payment_status,
        payment_method: bookings.payment_method,
        payment_amount: bookings.payment_amount,
        payment_date: bookings.payment_date,
        midtrans_order_id: bookings.midtrans_order_id,
        catatan: bookings.catatan,
        createdAt: bookings.createdAt,
        updatedAt: bookings.updatedAt,
        session_title: sessions.title,
        session_description: sessions.description,
        session_start_time: sessions.start_time,
        session_end_time: sessions.end_time,
        session_price: sessions.price,
        session_trainer_id: sessions.trainer_id,
        member_nama: users.nama,
        member_email: users.email,
    })
    .from(bookings)
    .leftJoin(sessions, eq(bookings.session_id, sessions.id))
    .leftJoin(users, eq(bookings.member_id, users.id))
    .where(eq(bookings.id, id))
    .limit(1);
    return rows[0] ?? null;
}

export async function findByMember(memberId: number) {
    const rows = await db.select({
        id: bookings.id,
        session_id: bookings.session_id,
        status: bookings.status,
        payment_status: bookings.payment_status,
        payment_amount: bookings.payment_amount,
        catatan: bookings.catatan,
        createdAt: bookings.createdAt,
        session_title: sessions.title,
        session_start_time: sessions.start_time,
        session_end_time: sessions.end_time,
        session_price: sessions.price,
        trainer_name: users.nama,
        trainer_photo: users.foto,
    })
    .from(bookings)
    .leftJoin(sessions, eq(bookings.session_id, sessions.id))
    .leftJoin(users, eq(sessions.trainer_id, users.id))
    .where(eq(bookings.member_id, memberId))
    .orderBy(desc(bookings.createdAt));
    return rows;
}

export async function findBySessionTrainer(trainerId: number) {
    const rows = await db.select({
        id: bookings.id,
        session_id: bookings.session_id,
        member_id: bookings.member_id,
        status: bookings.status,
        payment_status: bookings.payment_status,
        payment_amount: bookings.payment_amount,
        catatan: bookings.catatan,
        createdAt: bookings.createdAt,
        session_title: sessions.title,
        session_start_time: sessions.start_time,
        session_end_time: sessions.end_time,
        session_price: sessions.price,
        member_nama: users.nama,
        member_email: users.email,
    })
    .from(bookings)
    .leftJoin(sessions, eq(bookings.session_id, sessions.id))
    .leftJoin(users, eq(bookings.member_id, users.id))
    .where(eq(sessions.trainer_id, trainerId))
    .orderBy(desc(bookings.createdAt));
    return rows;
}

export async function checkExistingBooking(sessionId: number, memberId: number) {
    const rows = await db.select({ id: bookings.id })
    .from(bookings)
    .where(and(
        eq(bookings.session_id, sessionId),
        eq(bookings.member_id, memberId),
        ne(bookings.status, 'cancelled')
    ))
    .limit(1);
    return rows.length > 0;
}

export async function findCancelledBooking(sessionId: number, memberId: number) {
    const rows = await db.select({ id: bookings.id })
    .from(bookings)
    .where(and(
        eq(bookings.session_id, sessionId),
        eq(bookings.member_id, memberId),
        eq(bookings.status, 'cancelled')
    ))
    .limit(1);
    return rows[0] ?? null;
}

export async function reactivateBooking(id: number, catatan?: string) {
    const rows = await db.update(bookings)
    .set({
        status: 'pending' as any,
        payment_status: 'pending' as any,
        updatedAt: new Date(),
        ...(catatan !== undefined ? { catatan } : {}),
    })
    .where(eq(bookings.id, id))
    .returning();
    return rows[0] ?? null;
}

export async function create(data: {
    session_id: number;
    member_id: number;
    catatan?: string;
    payment_amount: string;
}) {
    const rows = await db.insert(bookings).values({
        session_id: data.session_id,
        member_id: data.member_id,
        catatan: data.catatan,
        payment_amount: data.payment_amount,
    }).returning();
    return rows[0];
}

export async function updateStatus(id: number, status: string) {
    const rows = await db.update(bookings)
    .set({ status: status as any, updatedAt: new Date() })
    .where(eq(bookings.id, id))
    .returning();
    return rows[0] ?? null;
}

export async function getSessionForBooking(sessionId: number) {
    const rows = await db.select({
        id: sessions.id,
        title: sessions.title,
        price: sessions.price,
        status: sessions.status,
        max_participants: sessions.max_participants,
        trainer_id: sessions.trainer_id,
    })
    .from(sessions)
    .where(eq(sessions.id, sessionId))
    .limit(1);
    return rows[0] ?? null;
}

export async function countConfirmedBookings(sessionId: number) {
    const result = await db.select({ count: sql<number>`count(*)` })
    .from(bookings)
    .where(and(eq(bookings.session_id, sessionId), eq(bookings.status, 'confirmed')));
    return Number(result[0].count);
}

export async function deleteByMember(memberId: number) {
    const result = await db.delete(bookings).where(eq(bookings.member_id, memberId)).returning({ id: bookings.id });
    return result.length;
}

export async function deleteAll() {
    const result = await db.delete(bookings).returning({ id: bookings.id });
    return result.length;
}
