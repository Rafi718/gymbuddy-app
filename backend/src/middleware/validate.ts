import type { Request, Response, NextFunction } from 'express';
import type { ZodSchema } from 'zod';
import { error } from '../utils/response';

export interface ValidatedRequest extends Request {
    validated?: {
        body?: unknown;
        params?: unknown;
        query?: unknown;
    };
}

export function validate(schema: ZodSchema) {
    return (req: ValidatedRequest, res: Response, next: NextFunction) => {
        const result = schema.safeParse({
            body: req.body,
            params: req.params,
            query: req.query,
        });
        if (!result.success) {
            return error(res, 'Input tidak valid', 400, 'VALIDATION_ERROR', result.error.issues);
        }
        req.validated = result.data as { body?: unknown; params?: unknown; query?: unknown };
        next();
    };
}
