import type { Request, Response, NextFunction } from 'express';
import { error } from '../utils/response';
import type { AuthedRequest } from './auth';

export function requireRole(...roles: string[]) {
    return (req: AuthedRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return error(res, 'Tidak terautentikasi', 401, 'UNAUTHORIZED');
        }
        if (!roles.includes(req.user.role)) {
            return error(res, 'Tidak memiliki izin untuk aksi ini', 403, 'FORBIDDEN');
        }
        next();
    };
}

export function requireOwnershipOrRole(...roles: string[]) {
    return (req: AuthedRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return error(res, 'Tidak terautentikasi', 401, 'UNAUTHORIZED');
        }
        const paramId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const resourceId = parseInt(paramId, 10);
        if (roles.includes(req.user.role)) {
            return next();
        }
        if (req.user.id === resourceId) {
            return next();
        }
        return error(res, 'Tidak memiliki izin untuk aksi ini', 403, 'FORBIDDEN');
    };
}
