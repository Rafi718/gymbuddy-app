import multer from 'multer';
import path from 'path';
import { error } from '../utils/response';

const storage = multer.diskStorage({
    destination: (req, _file, cb) => {
        cb(null, path.join(process.cwd(), 'uploads', 'profiles'));
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        const userId = (req as any).user?.id || 'unknown';
        cb(null, `profile_${userId}_${Date.now()}${ext}`);
    },
});

const fileFilter = (_req: any, file: any, cb: any) => {
    const allowed = /jpeg|jpg|png|webp/;
    const extOk = allowed.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowed.test(file.mimetype);
    if (extOk && mimeOk) return cb(null, true);
    cb(new Error('Format file tidak didukung. Gunakan JPG, PNG, atau WebP.'));
};

export const uploadMiddleware = multer({
    storage,
    limits: { fileSize: 2 * 1024 * 1024 },
    fileFilter,
});
