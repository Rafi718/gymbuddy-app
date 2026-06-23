import type { Response } from 'express';

export function success(res: Response, data: unknown, message?: string, statusCode = 200) {
    const body: { success: boolean; data: unknown; message?: string } = { success: true, data };
    if (message) body.message = message;
    return res.status(statusCode).json(body);
}

export function paginated(res: Response, data: unknown, meta: { page: number; limit: number; total: number; totalPages: number }, message?: string) {
    const body: { success: boolean; data: unknown; meta: unknown; message?: string } = { success: true, data, meta };
    if (message) body.message = message;
    return res.status(200).json(body);
}

export function error(res: Response, message: string, statusCode = 500, code?: string, details?: unknown) {
    const errorObj: { code: string; message: string; details?: unknown } = {
        code: code || defaultCode(statusCode),
        message,
    };
    if (details) errorObj.details = details;
    return res.status(statusCode).json({
        success: false,
        error: errorObj,
    });
}

function defaultCode(status: number): string {
    switch (status) {
        case 400: return 'VALIDATION_ERROR';
        case 401: return 'UNAUTHORIZED';
        case 403: return 'FORBIDDEN';
        case 404: return 'NOT_FOUND';
        case 409: return 'CONFLICT';
        case 429: return 'RATE_LIMITED';
        default: return 'INTERNAL_ERROR';
    }
}
