import type { Request, Response, NextFunction } from 'express';
import { error } from '../utils/response';
import { logger } from '../utils/logger';

export function notFoundHandler(req: Request, res: Response) {
    return error(res, `Route tidak ditemukan: ${req.method} ${req.originalUrl}`, 404, 'NOT_FOUND');
}

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction) {
    logger.error({ err, method: req.method, path: req.path }, 'Unhandled error');
    return error(res, err.message || 'Terjadi kesalahan server', 500, 'INTERNAL_ERROR');
}
