import { getDBPool } from '../config/db.js';
import bcrypt from 'bcrypt';
import { generateToken } from '../utils/jwt.js';
import cache from '../utils/cache.js';

export const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ message: 'Email dan password wajib diisi' });
        }

        const db = await getDBPool();
        
        // Cari user di tabel user (semua role: customer, trainer, admin)
        const userRows = await db.query(
            'SELECT id, nama, email, password, role, propinsi, kota FROM user WHERE email = ?',
            [email]
        );

        if (userRows.length === 0) {
            return res.status(401).json({ message: 'Email atau password salah' });
        }

        const user = userRows[0];

        // Verifikasi password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Email atau password salah' });
        }

        const token = generateToken({
            id: user.id,
            email: user.email,
            role: user.role
        });

        res.json({
            message: 'Login berhasil',
            token,
            user: {
                id: user.id,
                nama: user.nama,
                email: user.email,
                role: user.role,
                propinsi: user.propinsi,
                kota: user.kota
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Terjadi kesalahan server' });
    }
};

const validateBasicInfo = (nama, email, password) => {
    return nama && email && password;
};

// Register User (Customer)
export const registerUser = async (req, res) => {
    try {
        const { nama, email, password, propinsi, kota } = req.body;
        if (!validateBasicInfo(nama, email, password)) {
            return res.status(400).json({ message: 'Nama, email, dan password wajib diisi' });
        }

        const db = await getDBPool();
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const result = await db.query(
            'INSERT INTO user (nama, email, password, role, propinsi, kota) VALUES (?, ?, ?, ?, ?, ?)',
            [nama, email, passwordHash, 'customer', propinsi || '', kota || '']
        );

        cache.del('user_stats');
        res.status(201).json({ 
            id: result.insertId.toString(), 
            nama, 
            email, 
            role: 'customer', 
            message: 'Akun berhasil dibuat. Silakan login.' 
        });
    } catch (error) {
        if (error.code === '23505') {
            return res.status(400).json({ message: 'Email sudah terdaftar. Gunakan email lain.' });
        }
        console.error('Register error:', error);
        res.status(500).json({ message: 'Gagal mendaftarkan akun.' });
    }
};

// Register Trainer
export const registerTrainer = async (req, res) => {
    try {
        const { nama, email, password, propinsi, kota } = req.body;
        if (!validateBasicInfo(nama, email, password)) {
            return res.status(400).json({ message: 'Nama, email, dan password wajib diisi' });
        }

        const db = await getDBPool();
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const result = await db.query(
            'INSERT INTO user (nama, email, password, role, propinsi, kota) VALUES (?, ?, ?, ?, ?, ?)',
            [nama, email, passwordHash, 'trainer', propinsi || '', kota || '']
        );

        cache.del('all_trainers');
        cache.del('user_stats');
        res.status(201).json({ 
            id: result.insertId.toString(), 
            nama, 
            email, 
            role: 'trainer', 
            message: 'Akun trainer berhasil dibuat.' 
        });
    } catch (error) {
        if (error.code === '23505') {
            return res.status(400).json({ message: 'Email sudah terdaftar.' });
        }
        console.error('Register trainer error:', error);
        res.status(500).json({ message: 'Gagal mendaftarkan trainer.' });
    }
};

// Register Admin
export const registerAdmin = async (req, res) => {
    try {
        const { nama, email, password } = req.body;
        if (!validateBasicInfo(nama, email, password)) {
            return res.status(400).json({ message: 'Nama, email, dan password wajib diisi' });
        }

        const db = await getDBPool();
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const result = await db.query(
            'INSERT INTO user (nama, email, password, role) VALUES (?, ?, ?, ?)',
            [nama, email, passwordHash, 'admin']
        );

        res.status(201).json({ 
            id: result.insertId.toString(), 
            nama, 
            email, 
            role: 'admin', 
            message: 'Admin berhasil dibuat.' 
        });
    } catch (error) {
        if (error.code === '23505') {
            return res.status(400).json({ message: 'Email sudah terdaftar.' });
        }
        console.error('Register admin error:', error);
        res.status(500).json({ message: 'Gagal mendaftarkan admin.' });
    }
};

export const getMe = async (req, res) => {
    try {
        const userId = req.user.id;
        const db = await getDBPool();

        const rows = await db.query(
            'SELECT id, nama, email, role, propinsi, kota, created_at FROM user WHERE id = ?',
            [userId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ message: 'Terjadi kesalahan server' });
    }
};
