import { getDBPool } from '../config/db.js';
import { success, error } from '../utils/response.js';
import cache from '../utils/cache.js';

export const getPromoByCode = async (req, res) => {
    try {
        const { kode } = req.query;
        if (!kode) return error(res, 'Kode promo wajib diisi', 400);
        const db = await getDBPool();
        const rows = await db.query(
            'SELECT * FROM promo WHERE kode = ? AND is_active = 1 AND (tanggal_mulai IS NULL OR tanggal_mulai <= NOW()) AND (tanggal_selesai IS NULL OR tanggal_selesai >= NOW())',
            [kode]
        );
        if (!rows[0]) return error(res, 'Kode promo tidak valid atau sudah kadaluarsa', 404);
        return success(res, rows[0], 'Kode promo valid');
    } catch (err) {
        return error(res, 'Gagal memeriksa promo', 500);
    }
};

export const getAllPromo = async (req, res) => {
    try {
        const cacheKey = 'promo_list';
        const { search, is_active } = req.query;
        // Hanya pakai cache jika tidak ada filter
        if (!search && is_active === undefined) {
            const cached = cache.get(cacheKey);
            if (cached) return res.json({ success: true, data: cached, total: cached.length });
        }

        const db = await getDBPool();
        const { _page, _limit } = req.query;
        const page = parseInt(_page) || 1;
        const limit = parseInt(_limit) || 20;
        const offset = (page - 1) * limit;

        let query = 'SELECT * FROM promo WHERE 1=1';
        let countQuery = 'SELECT COUNT(*) as total FROM promo WHERE 1=1';
        let params = [];
        let countParams = [];

        if (search) { query += ' AND (judul LIKE ? OR kode LIKE ?)'; countQuery += ' AND (judul LIKE ? OR kode LIKE ?)'; params.push(`%${search}%`, `%${search}%`); countParams.push(`%${search}%`, `%${search}%`); }
        if (is_active !== undefined) { query += ' AND is_active = ?'; countQuery += ' AND is_active = ?'; params.push(is_active === 'true' ? 1 : 0); countParams.push(is_active === 'true' ? 1 : 0); }

        const [countResult, rows] = await Promise.all([
            db.query(countQuery, countParams),
            db.query(query + ' ORDER BY created_at DESC LIMIT ? OFFSET ?', [...params, limit, offset])
        ]);
        
        const total = countResult[0]?.total || 0;
        cache.set(cacheKey, rows, 600);
        
        res.setHeader('X-Total-Count', total);
        res.json({ success: true, data: rows, total });
    } catch (err) { return error(res, 'Gagal mengambil promo', 500); }
};

export const getPromoById = async (req, res) => {
    try {
        const db = await getDBPool();
        const rows = await db.query('SELECT * FROM promo WHERE id = ?', [req.params.id]);
        if (!rows[0]) return error(res, 'Promo tidak ditemukan', 404);
        return success(res, rows[0], 'Data promo');
    } catch (err) { return error(res, 'Gagal mengambil promo', 500); }
};

export const createPromo = async (req, res) => {
    try {
        const { kode, judul, deskripsi, tipe, nilai, min_booking, maks_diskon, kuota, tanggal_mulai, tanggal_selesai } = req.body;
        if (!kode || !judul || !tipe || !nilai) return error(res, 'Kode, judul, tipe, dan nilai wajib diisi', 400);
        const db = await getDBPool();
        const result = await db.query(
            'INSERT INTO promo (kode, judul, deskripsi, tipe, nilai, min_booking, maks_diskon, kuota, tanggal_mulai, tanggal_selesai) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [kode, judul, deskripsi || '', tipe, nilai, min_booking || 1, maks_diskon || null, kuota || null, tanggal_mulai || null, tanggal_selesai || null]
        );
        cache.del('promo_list');
        return success(res, { id: Number(result.insertId) }, 'Promo berhasil dibuat', 201);
    } catch (err) {
        if (err.code === '23505') return error(res, 'Kode promo sudah digunakan', 400);
        return error(res, 'Gagal membuat promo', 500);
    }
};

export const updatePromo = async (req, res) => {
    try {
        const db = await getDBPool();
        const allowed = ['kode','judul','deskripsi','tipe','nilai','min_booking','maks_diskon','kuota','is_active','tanggal_mulai','tanggal_selesai'];
        const fields = []; const values = [];
        for (const f of allowed) {
            if (req.body[f] !== undefined) { fields.push(`${f} = ?`); values.push(req.body[f]); }
        }
        if (fields.length === 0) return error(res, 'Tidak ada field yang diupdate', 400);
        values.push(req.params.id);
        await db.query(`UPDATE promo SET ${fields.join(', ')} WHERE id = ?`, values);
        cache.del('promo_list');
        return success(res, null, 'Promo berhasil diperbarui');
    } catch (err) { return error(res, 'Gagal memperbarui promo', 500); }
};

export const deletePromo = async (req, res) => {
    try {
        const db = await getDBPool();
        await db.query('DELETE FROM promo WHERE id = ?', [req.params.id]);
        cache.del('promo_list');
        return success(res, null, 'Promo berhasil dihapus');
    } catch (err) { return error(res, 'Gagal menghapus promo', 500); }
};
