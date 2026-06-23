import {getDBPool} from '../config/db.js';
import {success, error} from '../utils/response.js';
import cache from '../utils/cache.js';

export const getAllProgress = async (req, res) => {
    try {
        const db = await getDBPool();
        const rows = await db.query(
            `SELECT p.id, p.member_id, p.booking_id, p.activity, p.duration, p.note, p.recorded_at,
                    u.nama as member_name
             FROM progress p
             JOIN user u ON p.member_id = u.id`
        );
        return success(res, rows, 'Semua data progress berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const getMyProgress = async (req, res) => {
    try {
        const member_id = req.user.id;
        const db = await getDBPool();

        const rows = await db.query(
            `SELECT id, activity, duration, note, recorded_at 
             FROM progress 
             WHERE member_id = ? 
             ORDER BY recorded_at DESC`,
            [member_id]
        );

        return success(res, rows, 'Data progress berhasil diambil');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const createProgress = async (req, res) => {
    try {
        const { activity, duration, note, booking_id } = req.body;
        const member_id = req.user.id;

        if (req.user.role !== 'customer') {
            return error(res, 'Hanya customer yang bisa mencatat progress', 403);
        }

        if (!activity || !duration) {
            return error(res, 'Aktivitas dan durasi wajib diisi', 400);
        }

        const db = await getDBPool();

        if (booking_id) {
            const booking = await db.query(
                "SELECT id FROM booking WHERE id = ? AND member_id = ? AND status = 'Confirmed'",
                [booking_id, member_id]
            );
            if (booking.length === 0) {
                return error(res, 'Booking tidak ditemukan atau belum dikonfirmasi', 400);
            }
        }

        const result = await db.query(
            'INSERT INTO progress (member_id, booking_id, activity, duration, note) VALUES (?, ?, ?, ?, ?)',
            [member_id, booking_id || null, activity, duration, note || '']
        );

        return success(res, { id: Number(result.insertId) }, 'Progress berhasil dicatat', 201);
    } catch (err) {
        console.error('Error createProgress:', err);
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const updateProgress = async (req, res) => {
    try {
        const { id } = req.params;
        const { activity, duration, note } = req.body;
        const member_id = req.user.id;

        const db = await getDBPool();

        const progressRows = await db.query('SELECT id, member_id FROM progress WHERE id = ?', [id]);
        if (progressRows.length === 0) {
            return error(res, 'Data progress tidak ditemukan', 404);
        }

        if (req.user.role !== 'admin' && progressRows[0].member_id !== member_id) {
            return error(res, 'Tidak memiliki izin', 403);
        }

        const fields = [];
        const values = [];

        if (activity !== undefined) { fields.push('activity = ?'); values.push(activity); }
        if (duration !== undefined) { fields.push('duration = ?'); values.push(duration); }
        if (note !== undefined)     { fields.push('note = ?');     values.push(note); }

        if (fields.length === 0) {
            return error(res, 'Tidak ada field yang diupdate', 400);
        }

        values.push(id);
        await db.query(`UPDATE progress SET ${fields.join(', ')} WHERE id = ?`, values);

        return success(res, null, 'Progress berhasil diperbarui');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};

export const deleteProgress = async (req, res) => {
    try {
        const { id } = req.params;
        const db = await getDBPool();

        const progressRows = await db.query('SELECT member_id FROM progress WHERE id = ?', [id]);
        if (progressRows.length === 0) {
            return error(res, 'Data progress tidak ditemukan', 404);
        }

        if (req.user.role !== 'admin' && progressRows[0].member_id !== req.user.id) {
            return error(res, 'Tidak memiliki izin', 403);
        }

        const result = await db.query('DELETE FROM progress WHERE id = ?', [id]);
        if (result.affectedRows === 0) {
            return error(res, 'Data progress tidak ditemukan', 404);
        }

        return success(res, null, 'Progress berhasil dihapus');
    } catch (err) {
        return error(res, 'Terjadi kesalahan server', 500);
    }
};
