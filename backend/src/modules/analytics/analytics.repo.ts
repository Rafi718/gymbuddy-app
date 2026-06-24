import { sql } from 'drizzle-orm';
import { db } from '../../db/client';
import { users } from '../../db/schema';
import { sessions } from '../../db/schema/sessions';
import { bookings } from '../../db/schema/bookings';

export async function getDashboardStats() {
    // Total users by role
    const roleStats = await db.select({
        role: users.role,
        count: sql<number>`count(*)`,
    })
    .from(users)
    .groupBy(users.role);

    // Total bookings by status
    const bookingStatusStats = await db.select({
        status: bookings.status,
        count: sql<number>`count(*)`,
    })
    .from(bookings)
    .groupBy(bookings.status);

    // Payment status counts
    const paymentStats = await db.select({
        payment_status: bookings.payment_status,
        count: sql<number>`count(*)`,
    })
    .from(bookings)
    .groupBy(bookings.payment_status);

    // Total sessions
    const sessionCountResult = await db.select({
        count: sql<number>`count(*)`,
    })
    .from(sessions);

    // Total revenue from settled payments
    const revenueResult = await db.select({
        total: sql<string>`coalesce(sum(${bookings.payment_amount}), 0)`,
    })
    .from(bookings)
    .where(sql`${bookings.payment_status} = 'settlement'`);

    const totalUsers = roleStats.reduce((acc, r) => acc + Number(r.count), 0);
    const totalBookings = bookingStatusStats.reduce((acc, b) => acc + Number(b.count), 0);
    const settledPayments = paymentStats.find(p => p.payment_status === 'settlement')?.count ?? 0;
    const totalSessions = Number(sessionCountResult[0]?.count ?? 0);
    const totalRevenue = Number(revenueResult[0]?.total ?? 0);

    return {
        totalUsers,
        totalSessions,
        totalBookings,
        settledPayments: Number(settledPayments),
        totalRevenue,
        roleDistribution: roleStats.map(r => ({
            role: r.role,
            count: Number(r.count),
        })),
        bookingStatusDistribution: bookingStatusStats.map(b => ({
            status: b.status,
            count: Number(b.count),
        })),
        paymentStatusDistribution: paymentStats.map(p => ({
            payment_status: p.payment_status,
            count: Number(p.count),
        })),
    };
}
