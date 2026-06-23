import { getDBPool } from '../config/db.js';
import { success, error } from '../utils/response.js';
import cache from '../utils/cache.js';

export const CustomerBookingHistory = async (req, res) => {
    try {
        const cacheKey = 'view_customer_booking_history';
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT b.id as booking_id, s.title as session_title, s.start_time, s.end_time,
                    u.nama as customer_name, u.id as customer_id,
                    tr.nama as trainer_name, b.status, b.datetime_created as booked_on
             FROM booking b
             JOIN session s ON b.session_id = s.id
             JOIN user u ON b.member_id = u.id
             JOIN user tr ON s.trainer_id = tr.id
             ORDER BY b.datetime_created DESC`
        );

        cache.set(cacheKey, rows, 300);
        return success(res, rows, 'Riwayat booking berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const CustomerBookingHistoryId = async (req, res) => {
    try {
        const { id } = req.params;
        if (req.user.role !== 'admin' && req.user.id !== parseInt(id)) {
            return error(res, 'Akses ditolak', 403);
        }

        const cacheKey = `view_customer_booking_history_${id}`;
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT b.id as booking_id, s.title as session_title, s.start_time, s.end_time,
                    u.nama as customer_name, tr.nama as trainer_name, b.status, b.datetime_created as booked_on
             FROM booking b
             JOIN session s ON b.session_id = s.id
             JOIN user u ON b.member_id = u.id
             JOIN user tr ON s.trainer_id = tr.id
             WHERE b.member_id = ?
             ORDER BY b.datetime_created DESC`,
            [id]
        );

        cache.set(cacheKey, rows, 300);
        return success(res, rows, 'Riwayat booking berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const matched_trainer_customer = async (req, res) => {
    try {
        const cacheKey = 'view_matched_trainer_customer';
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT b.id as booking_id, s.id as session_id, s.title as session_title, s.start_time,
                    tr.id as trainer_id, tr.nama as trainer_name, tr.email as trainer_email,
                    u.id as customer_id, u.nama as customer_name, u.email as customer_email,
                    b.status, b.datetime_created
             FROM booking b
             JOIN session s ON b.session_id = s.id
             JOIN user tr ON s.trainer_id = tr.id
             JOIN user u ON b.member_id = u.id
             WHERE b.status = 'Confirmed'`
        );

        cache.set(cacheKey, rows, 600);
        return success(res, rows, 'Data matching berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

/**
 * Get booking history for trainers (their own sessions' bookings)
 */
export const getTrainerBookingHistory = async (req, res) => {
    try {
        const trainer_id = req.user.id;

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT b.id as booking_id, s.title as session_title, s.start_time, s.end_time,
                    u.nama as customer_name, u.id as customer_id, u.email as customer_email,
                    tr.nama as trainer_name, b.status, b.payment_status, b.payment_amount,
                    b.datetime_created as booked_on
             FROM booking b
             JOIN session s ON b.session_id = s.id
             JOIN user u ON b.member_id = u.id
             JOIN user tr ON s.trainer_id = tr.id
             WHERE s.trainer_id = ?
             ORDER BY b.datetime_created DESC`,
            [trainer_id]
        );

        return success(res, rows, 'Riwayat booking trainer berhasil diambil');
    } catch (err) {
        console.error('[getTrainerBookingHistory] Error:', err.message, err.stack);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const member_progress_summary = async (req, res) => {
    try {
        const cacheKey = 'view_member_progress_summary';
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT p.id as progress_id, u.id as member_id, u.nama as member_name,
                    p.activity, p.duration, p.note, p.recorded_at
             FROM progress p
             JOIN "user" u ON p.member_id = u.id
             ORDER BY p.recorded_at DESC`
        );

        cache.set(cacheKey, rows, 300);
        return success(res, rows, 'Data progress berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const member_progress_summary_id = async (req, res) => {
    try {
        const { id } = req.params;
        if (req.user.role !== 'admin' && req.user.id !== parseInt(id)) {
            return error(res, 'Akses ditolak', 403);
        }

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT p.id as progress_id, u.id as member_id, u.nama as member_name,
                    p.activity, p.duration, p.note, p.recorded_at
             FROM progress p
             JOIN "user" u ON p.member_id = u.id
             WHERE p.member_id = ?
             ORDER BY p.recorded_at DESC`,
            [id]
        );

        return success(res, rows, 'Data progress berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const trainer_schedule = async (req, res) => {
    try {
        const { id } = req.params;
        const trainerId = id || req.user.id;

        const db = await getDBPool();

        const rows = await db.query(
            `SELECT s.*, 
                (SELECT COUNT(*) FROM booking b WHERE b.session_id = s.id AND b.status = 'Confirmed') as confirmed_customers
             FROM session s 
             WHERE s.trainer_id = ?
             ORDER BY s.start_time ASC`,
            [trainerId]
        );

        return success(res, rows, 'Jadwal trainer berhasil diambil');
    } catch (err) {
        console.error("Error trainer_schedule:", err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const upcoming_sessions_for_members = async (req, res) => {
    try {
        const db = await getDBPool();
        const rows = await db.query(
            `SELECT s.id, s.title, s.deskripsi, s.trainer_id, s.start_time, s.end_time, s.price,
                    u.nama as trainer_name,
                    (SELECT COUNT(*) FROM booking b WHERE b.session_id = s.id AND b.status = 'Confirmed') as confirmed_customers,
                    (SELECT COUNT(*) FROM booking b WHERE b.session_id = s.id) as total_bookings
             FROM session s
             JOIN user u ON s.trainer_id = u.id
             WHERE s.start_time > NOW()
             ORDER BY s.start_time ASC`
        );

        return success(res, rows, 'Sesi mendatang berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const session_participants = async (req, res) => {
    try {
        const { id } = req.params;
        const db = await getDBPool();

        let query = `
            SELECT b.id as booking_id, b.status, 
                   u.id as customer_id, u.nama as customer_name,
                   s.id as session_id, s.title as session_title, s.trainer_id
            FROM booking b
            JOIN session s ON b.session_id = s.id
            JOIN user u ON b.member_id = u.id
        `;
        let params = [];

        if (id && id !== 'undefined') {
            query += ' WHERE s.id = ?';
            params.push(id);
        }

        const rows = await db.query(query, params);
        return success(res, rows, 'Data peserta berhasil diambil');
    } catch (err) {
        console.error("Error session_participants:", err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const session_reviews_summary = async (req, res) => {
    try {
        const { id } = req.params;
        const cacheKey = id ? `view_session_reviews_summary_${id}` : 'view_session_reviews_summary';

        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        let query = `
            SELECT r.id as review_id, s.id as session_id, s.title as session_title,
                   u.nama as customer_name, tr.nama as trainer_name,
                   r.rating_score, r.comment, r.datetime_created
            FROM reviews r
            JOIN session s ON r.session_id = s.id
            JOIN user u ON r.member_id = u.id
            JOIN user tr ON s.trainer_id = tr.id
        `;
        let params = [];

        if (id) {
            query += ' WHERE s.id = ?';
            params = [id];
        }
        
        query += ' ORDER BY r.datetime_created DESC';

        const rows = await db.query(query, params);
        cache.set(cacheKey, rows, 600);

        return success(res, rows, 'Review berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};
