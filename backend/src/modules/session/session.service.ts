import { findAll, findById, findUpcoming, create, update, remove, isOwner, countBookingsForSession } from './session.repo';

export class SessionError extends Error {
    constructor(
        public statusCode: number,
        public code: string,
        message: string,
    ) {
        super(message);
    }
}

export async function listSessions(opts: {
    page: number;
    limit: number;
    search?: string;
    trainer_id?: number;
    status?: string;
    sort: string;
    order: string;
}) {
    const { rows, total } = await findAll(opts);
    const totalPages = Math.ceil(total / opts.limit);

    const rowsWithBookingCount = await Promise.all(
        rows.map(async (session) => ({
            ...session,
            booking_count: await countBookingsForSession(session.id),
        })),
    );

    return {
        data: rowsWithBookingCount,
        meta: { page: opts.page, limit: opts.limit, total, totalPages },
    };
}

export async function getSessionById(id: number) {
    const session = await findById(id);
    if (!session) {
        throw new SessionError(404, 'NOT_FOUND', 'Sesi tidak ditemukan');
    }
    return session;
}

export async function getUpcomingSessions(limit = 10) {
    return await findUpcoming(limit);
}

export async function createSession(data: {
    title: string;
    description?: string;
    trainer_id: number;
    start_time: string;
    end_time?: string;
    price: number;
    max_participants: number;
}) {
    const session = await create({
        title: data.title,
        description: data.description,
        trainer_id: data.trainer_id,
        start_time: new Date(data.start_time),
        end_time: data.end_time ? new Date(data.end_time) : undefined,
        price: data.price,
        max_participants: data.max_participants,
    });
    return session;
}

export async function updateSession(
    id: number,
    data: Record<string, unknown>,
    userId: number,
    userRole: string,
) {
    const session = await findById(id);
    if (!session) {
        throw new SessionError(404, 'NOT_FOUND', 'Sesi tidak ditemukan');
    }

    if (userRole !== 'admin' && session.trainer_id !== userId) {
        throw new SessionError(403, 'FORBIDDEN', 'Anda tidak memiliki izin untuk mengubah sesi ini');
    }

    const updated = await update(id, data);
    return updated;
}

export async function deleteSession(id: number, userId: number, userRole: string) {
    const session = await findById(id);
    if (!session) {
        throw new SessionError(404, 'NOT_FOUND', 'Sesi tidak ditemukan');
    }

    if (userRole !== 'admin' && session.trainer_id !== userId) {
        throw new SessionError(403, 'FORBIDDEN', 'Anda tidak memiliki izin untuk menghapus sesi ini');
    }

    const bookingCount = await countBookingsForSession(id);
    if (bookingCount > 0) {
        throw new SessionError(
            409,
            'CONFLICT',
            `Sesi ini sudah memiliki ${bookingCount} booking. Hapus atau batalkan semua booking terlebih dahulu sebelum menghapus sesi.`,
        );
    }

    await remove(id);
    return true;
}
