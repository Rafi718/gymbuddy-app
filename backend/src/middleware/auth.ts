import type { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { error } from '../utils/response';

export interface AuthedRequest extends Request {
    user?: { id: number; role: string };
}

export function authMiddleware(req: AuthedRequest, res: Response, next: NextFunction) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
        return error(res, 'Token tidak ditemukan', 401, 'UNAUTHORIZED');
    }

    const token = header.slice(7);
    const decoded = verifyToken(token);
    if (!decoded) {
        return error(res, 'Token tidak valid atau sudah kedaluwarsa', 401, 'UNAUTHORIZED');
    }

    req.user = decoded;
    next();
}
