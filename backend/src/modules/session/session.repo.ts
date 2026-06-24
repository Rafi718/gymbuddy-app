import { eq, ilike, and, desc, asc, sql, gt } from 'drizzle-orm';
import { db } from '../../db/client';
import { sessions, users, bookings } from '../../db/schema';

export async function findAll(opts: {
    page: number;
    limit: number;
    search?: string;
    trainer_id?: number;
    status?: string;
    sort: string;
    order: string;
}) {
    const conditions = [];
    if (opts.search) {
        conditions.push(ilike(sessions.title, `%${opts.search}%`));
    }
    if (opts.trainer_id) {
        conditions.push(eq(sessions.trainer_id, opts.trainer_id));
    }
    if (opts.status) {
        conditions.push(eq(sessions.status, opts.status as any));
    }

    const where = conditions.length > 0 ? and(...conditions) : undefined;

    const sortCol = opts.sort === 'price' ? sessions.price : opts.sort === 'created_at' ? sessions.createdAt : sessions.start_time;
    const orderFn = opts.order === 'asc' ? asc : desc;

    const rows = await db.select({
        id: sessions.id,
        title: sessions.title,
        description: sessions.description,
        trainer_id: sessions.trainer_id,
        trainer_name: users.nama,
        trainer_photo: users.foto,
        start_time: sessions.start_time,
        end_time: sessions.end_time,
        price: sessions.price,
        status: sessions.status,
        max_participants: sessions.max_participants,
        createdAt: sessions.createdAt,
        updatedAt: sessions.updatedAt,
    })
    .from(sessions)
    .leftJoin(users, eq(sessions.trainer_id, users.id))
    .where(where)
    .orderBy(orderFn(sortCol))
    .limit(opts.limit)
    .offset((opts.page - 1) * opts.limit);

    const countResult = await db.select({ count: sql<number>`count(*)` })
    .from(sessions)
    .where(where);
    const total = Number(countResult[0].count);

    return { rows, total };
}

export async function findById(id: number) {
    const rows = await db.select({
        id: sessions.id,
        title: sessions.title,
        description: sessions.description,
        trainer_id: sessions.trainer_id,
        trainer_name: users.nama,
        trainer_photo: users.foto,
        trainer_email: users.email,
        trainer_spesialisasi: users.spesialisasi,
        trainer_bio: users.bio,
        start_time: sessions.start_time,
        end_time: sessions.end_time,
        price: sessions.price,
        status: sessions.status,
        max_participants: sessions.max_participants,
        createdAt: sessions.createdAt,
        updatedAt: sessions.updatedAt,
    })
    .from(sessions)
    .leftJoin(users, eq(sessions.trainer_id, users.id))
    .where(eq(sessions.id, id))
    .limit(1);
    return rows[0] ?? null;
}

export async function findUpcoming(limit = 10) {
    const now = new Date();
    const rows = await db.select({
        id: sessions.id,
        title: sessions.title,
        description: sessions.description,
        trainer_id: sessions.trainer_id,
        trainer_name: users.nama,
        start_time: sessions.start_time,
        end_time: sessions.end_time,
        price: sessions.price,
        status: sessions.status,
        max_participants: sessions.max_participants,
    })
    .from(sessions)
    .leftJoin(users, eq(sessions.trainer_id, users.id))
    .where(and(eq(sessions.status, 'scheduled'), gt(sessions.start_time, now)))
    .orderBy(asc(sessions.start_time))
    .limit(limit);
    return rows;
}

export async function create(data: {
    title: string;
    description?: string;
    trainer_id: number;
    start_time: Date;
    end_time?: Date;
    price: number;
    max_participants: number;
}) {
    const rows = await db.insert(sessions).values({
        title: data.title,
        description: data.description,
        trainer_id: data.trainer_id,
        start_time: data.start_time,
        end_time: data.end_time,
        price: data.price.toString(),
        max_participants: data.max_participants,
    }).returning();
    return rows[0];
}

export async function update(id: number, data: Record<string, unknown>) {
    const updateData: Record<string, unknown> = { ...data, updatedAt: new Date() };
    if (data.price !== undefined) updateData.price = String(data.price);
    if (data.start_time) updateData.start_time = new Date(data.start_time as string);
    if (data.end_time) updateData.end_time = new Date(data.end_time as string);

    const rows = await db.update(sessions)
    .set(updateData)
    .where(eq(sessions.id, id))
    .returning();
    return rows[0] ?? null;
}

export async function countBookingsForSession(sessionId: number) {
    const result = await db.select({ count: sql<number>`count(*)` })
        .from(bookings)
        .where(eq(bookings.session_id, sessionId));
    return Number(result[0]?.count || 0);
}

export async function remove(id: number) {
    await db.delete(sessions).where(eq(sessions.id, id));
    return true;
}

export async function isOwner(trainerId: number, sessionId: number) {
    const rows = await db.select({ trainer_id: sessions.trainer_id })
    .from(sessions)
    .where(eq(sessions.id, sessionId))
    .limit(1);
    return rows[0]?.trainer_id === trainerId;
}

export async function findByTrainer(trainerId: number) {
    const rows = await db.select({
        id: sessions.id,
        title: sessions.title,
        description: sessions.description,
        start_time: sessions.start_time,
        end_time: sessions.end_time,
        price: sessions.price,
        status: sessions.status,
        max_participants: sessions.max_participants,
        createdAt: sessions.createdAt,
    })
    .from(sessions)
    .where(eq(sessions.trainer_id, trainerId))
    .orderBy(desc(sessions.createdAt));
    return rows;
}
