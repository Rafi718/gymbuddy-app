import {getDBPool} from '../config/db.js';
import {success, error} from '../utils/response.js';
import cache from '../utils/cache.js';

const isValidTrainer = async (db, trainer_id) => {
    const rows = await db.query("SELECT id FROM user WHERE id = ? AND role = 'trainer'", [trainer_id]);
    return rows.length > 0;
};

export const getAllSessions = async (req, res) => {
    try {
        const cacheKey = 'all_sessions';
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT s.id, s.title, s.deskripsi, s.trainer_id, s.start_time, s.end_time, s.price, s.status,
                    u.nama as trainer_name, u.foto as trainer_photo
             FROM session s
             JOIN user u ON s.trainer_id = u.id`
        );

        cache.set(cacheKey, rows, 600);
        return success(res, rows, 'Semua sesi berhasil diambil');
    } catch (err) {
        console.error('Fetch sessions error:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const getSessionById = async (req, res) => {
    try {
        const {id} = req.params;
        const cacheKey = `session_${id}`;
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT s.id, s.title, s.deskripsi, s.trainer_id, s.start_time, s.end_time, s.price, s.status,
                    u.nama as trainer_name, u.foto as trainer_photo
             FROM session s
             JOIN user u ON s.trainer_id = u.id
             WHERE s.id = ?`,
            [id]
        );
        if (rows.length === 0) return error(res, 'Sesi tidak ditemukan', 404);

        cache.set(cacheKey, rows[0], 600);
        return success(res, rows[0], 'Data sesi berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const createSession = async (req, res) => {
    try {
        const {title, deskripsi, trainer_id, start_time, end_time, price, status = 'scheduled'} = req.body;

        if (!title || !trainer_id || !start_time) {
            return error(res, 'Judul, trainer_id, dan start_time wajib diisi', 400);
        }

        const db = await getDBPool();

        if (!(await isValidTrainer(db, trainer_id))) {
            return error(res, 'Trainer tidak valid', 400);
        }

        const result = await db.query(
            'INSERT INTO session (title, deskripsi, trainer_id, start_time, end_time, price, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [title, deskripsi || '', trainer_id, start_time, end_time, price || 0, status]
        );

        cache.del('all_sessions');
        cache.del('upcoming_sessions');

        return success(res, {id: Number(result.insertId)}, 'Sesi berhasil dibuat', 201);
    } catch (err) {
        console.error('Create session error:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

const validSessionStatuses = ['scheduled', 'ongoing', 'completed', 'cancelled'];

export const updateSession = async (req, res) => {
    try {
        const { id } = req.params;
        const db = await getDBPool();

        const allowedFields = ['title', 'deskripsi', 'trainer_id', 'start_time', 'end_time', 'price', 'status'];
        const fields = [];
        const values = [];

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                if (field === 'trainer_id') {
                    if (!(await isValidTrainer(db, req.body.trainer_id))) {
                        return error(res, 'Trainer tidak valid', 400);
                    }
                }
                if (field === 'status') {
                    if (!validSessionStatuses.includes(req.body.status)) {
                        return error(res, `Status tidak valid. Pilihan: ${validSessionStatuses.join(', ')}`, 400);
                    }
                }
                fields.push(`${field} = ?`);
                values.push(req.body[field]);
            }
        }

        if (fields.length === 0) {
            return error(res, 'Tidak ada field yang diupdate', 400);
        }

        values.push(id);
        const result = await db.query(`UPDATE session SET ${fields.join(', ')} WHERE id = ?`, values);

        if (result.affectedRows === 0) {
            return error(res, 'Sesi tidak ditemukan', 404);
        }

        cache.del('all_sessions');
        cache.del(`session_${id}`);
        cache.del('upcoming_sessions');

        return success(res, null, 'Sesi berhasil diperbarui');
    } catch (err) {
        console.error('Update session error:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const deleteSession = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const userRole = req.user.role;

        const db = await getDBPool();
        const sessionRows = await db.query('SELECT trainer_id FROM session WHERE id = ?', [id]);

        if (!sessionRows || sessionRows.length === 0) return error(res, 'Sesi tidak ditemukan', 404);

        if (userRole !== 'admin' && sessionRows[0].trainer_id !== userId) {
            return error(res, 'Tidak memiliki izin untuk menghapus sesi ini', 403);
        }

        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            await connection.query('DELETE FROM booking WHERE session_id = ?', [id]);
            await connection.query('DELETE FROM session WHERE id = ?', [id]);
            await connection.commit();

            cache.del('all_sessions');
            cache.del(`session_${id}`);
            cache.del('upcoming_sessions');

            return success(res, null, 'Sesi berhasil dihapus');
        } catch (err) {
            await connection.rollback();
            console.error('Delete session transaction error:', err);
            return error(res, 'Gagal menghapus sesi', 500);
        } finally {
            connection.release();
        }
    } catch (err) {
        console.error('Delete session error:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const getUpcomingSessions = async (req, res) => {
    try {
        const cacheKey = 'upcoming_sessions';
        const cachedData = cache.get(cacheKey);
        if (cachedData) return success(res, cachedData, 'Data dari cache');

        const db = await getDBPool();
        const rows = await db.query(
            `SELECT s.id, s.title, s.deskripsi, s.trainer_id, s.start_time, s.end_time, s.price, s.status,
                    u.nama as trainer_name, u.foto as trainer_photo,
                    (SELECT COUNT(*) FROM booking b WHERE b.session_id = s.id AND b.status = 'Confirmed') as total_bookings
             FROM session s
             JOIN user u ON s.trainer_id = u.id
             WHERE s.start_time > NOW() AND s.status = 'scheduled'
             ORDER BY s.start_time ASC`
        );

        cache.set(cacheKey, rows, 300);
        return success(res, rows, 'Sesi mendatang berhasil diambil');
    } catch (err) {
        console.error('Fetch upcoming sessions error:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};
