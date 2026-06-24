import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/role';
import { getDashboardStatsController } from './analytics.controller';

const router = Router();

router.get('/dashboard', authMiddleware, requireRole('admin'), getDashboardStatsController);

export default router;
