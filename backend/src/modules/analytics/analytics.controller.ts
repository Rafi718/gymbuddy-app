import type { Response } from 'express';
import { success, error } from '../../utils/response';
import { logger } from '../../utils/logger';
import { getDashboardStats } from './analytics.repo';

export async function getDashboardStatsController(_req: any, res: Response) {
    try {
        const stats = await getDashboardStats();
        return success(res, stats, 'Berhasil');
    } catch (err) {
        logger.error({ err }, '[ANALYTICS] Gagal mengambil statistik dashboard');
        return error(res, 'Gagal mengambil statistik', 500, 'INTERNAL_ERROR');
    }
}
