import { getDBPool } from '../config/db.js';
import { success, error } from '../utils/response.js';
import cache from '../utils/cache.js';

export const getAllArticles = async (req, res) => {
    try {
        const db = await getDBPool();
        const { search, kategori, status, _page, _limit } = req.query;
        const page = parseInt(_page) || 1;
        const limit = parseInt(_limit) || 20;
        const offset = (page - 1) * limit;

        let query = 'SELECT a.*, u.nama as author_name FROM articles a LEFT JOIN user u ON a.author_id = u.id WHERE 1=1';
        let countQuery = 'SELECT COUNT(*) as total FROM articles WHERE 1=1';
        let queryParams = [];
        let countParams = [];

        if (search) { 
            query += ' AND (a.title LIKE ? OR a.excerpt LIKE ?)'; 
            countQuery += ' AND (title LIKE ? OR excerpt LIKE ?)'; 
            queryParams.push(`%${search}%`, `%${search}%`);
            countParams.push(`%${search}%`, `%${search}%`);
        }
        if (kategori) { 
            query += ' AND a.kategori = ?'; 
            countQuery += ' AND kategori = ?'; 
            queryParams.push(kategori);
            countParams.push(kategori);
        }
        if (status !== undefined) { 
            query += ' AND a.is_published = ?'; 
            countQuery += ' AND is_published = ?'; 
            queryParams.push(status === 'true' ? 1 : 0);
            countParams.push(status === 'true' ? 1 : 0);
        }

        query += ' ORDER BY a.created_at DESC LIMIT ? OFFSET ?';
        queryParams.push(limit, offset);

        const [countResult, rows] = await Promise.all([
            db.query(countQuery, countParams),
            db.query(query, queryParams)
        ]);

        // Handle result format from db wrapper
        const countData = Array.isArray(countResult) ? countResult[0] : countResult;
        const rowData = Array.isArray(rows) && rows.length > 0 && Array.isArray(rows[0]) ? rows[0] : rows;
        const total = countData?.total || 0;
        res.setHeader('X-Total-Count', total);
        res.json({ success: true, data: rowData || [], total });
    } catch (err) { return error(res, 'Gagal mengambil artikel', 500); }
};

export const getArticleById = async (req, res) => {
    try {
        const db = await getDBPool();
        const rows = await db.query('SELECT a.*, u.nama as author_name FROM articles a LEFT JOIN user u ON a.author_id = u.id WHERE a.id = ?', [req.params.id]);
        if (!rows[0]) return error(res, 'Artikel tidak ditemukan', 404);
        return success(res, rows[0], 'Data artikel');
    } catch (err) { return error(res, 'Gagal mengambil artikel', 500); }
};

export const createArticle = async (req, res) => {
    try {
        const { title, slug, content, excerpt, kategori, foto, is_published } = req.body;
        if (!title || !slug) return error(res, 'Judul dan slug wajib diisi', 400);
        const db = await getDBPool();
        const result = await db.query(
            'INSERT INTO articles (title, slug, content, excerpt, kategori, author_id, foto, is_published, published_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [title, slug, content || '', excerpt || '', kategori || 'Workout', req.user.id, foto || null, is_published ? 1 : 0, is_published ? new Date() : null]
        );
        cache.del('articles_list');
        return success(res, { id: Number(result.insertId) }, 'Artikel berhasil dibuat', 201);
    } catch (err) {
        if (err.code === '23505') return error(res, 'Slug sudah digunakan', 400);
        return error(res, 'Gagal membuat artikel', 500);
    }
};

export const updateArticle = async (req, res) => {
    try {
        const { title, slug, content, excerpt, kategori, foto, is_published } = req.body;
        const db = await getDBPool();
        const fields = []; const values = [];
        if (title !== undefined) { fields.push('title = ?'); values.push(title); }
        if (slug !== undefined) { fields.push('slug = ?'); values.push(slug); }
        if (content !== undefined) { fields.push('content = ?'); values.push(content); }
        if (excerpt !== undefined) { fields.push('excerpt = ?'); values.push(excerpt); }
        if (kategori !== undefined) { fields.push('kategori = ?'); values.push(kategori); }
        if (foto !== undefined) { fields.push('foto = ?'); values.push(foto); }
        if (is_published !== undefined) { fields.push('is_published = ?, published_at = ?'); values.push(is_published ? 1 : 0, is_published ? new Date() : null); }
        if (fields.length === 0) return error(res, 'Tidak ada field yang diupdate', 400);
        values.push(req.params.id);
        await db.query(`UPDATE articles SET ${fields.join(', ')} WHERE id = ?`, values);
        cache.del('articles_list');
        return success(res, null, 'Artikel berhasil diperbarui');
    } catch (err) { return error(res, 'Gagal memperbarui artikel', 500); }
};

export const deleteArticle = async (req, res) => {
    try {
        const db = await getDBPool();
        await db.query('DELETE FROM articles WHERE id = ?', [req.params.id]);
        cache.del('articles_list');
        return success(res, null, 'Artikel berhasil dihapus');
    } catch (err) { return error(res, 'Gagal menghapus artikel', 500); }
};
