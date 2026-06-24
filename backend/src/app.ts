import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { rateLimit } from 'express-rate-limit';
import path from 'path';
import { env } from './config/env';
import { notFoundHandler, errorHandler } from './middleware/error';
import authRoutes from './modules/auth/auth.routes';
import userRoutes from './modules/user/user.routes';
import sessionRoutes from './modules/session/session.routes';
import trainerRoutes from './modules/trainer/trainer.routes';
import bookingRoutes from './modules/booking/booking.routes';
import paymentRoutes from './modules/payment/payment.routes';
import reviewRoutes from './modules/review/review.routes';
import progressRoutes from './modules/progress/progress.routes';
import notificationRoutes from './modules/notification/notification.routes';
import articleRoutes from './modules/article/article.routes';
import promoRoutes from './modules/promo/promo.routes';
import bannerRoutes from './modules/banner/banner.routes';
import faqRoutes from './modules/faq/faq.routes';
import reminderRoutes from './modules/reminder/reminder.routes';
import dietRoutes from './modules/diet/diet.routes';
import uploadRoutes from './modules/upload/upload.routes';
import analyticsRoutes from './modules/analytics/analytics.routes';

const app = express();

app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(compression());

const allowedOrigins = [
    env.FRONTEND_URL,
    'http://localhost:5173',
    'http://localhost:3000',
    'http://localhost:5000',
];

app.use(cors({
    origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        if (allowedOrigins.includes(origin) || env.NODE_ENV === 'development') {
            return callback(null, true);
        }
        return callback(null, true);
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true,
}));

app.use(express.json({ type: ['application/json', 'text/plain'], limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: env.NODE_ENV === 'development' ? 2000 : 200,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: { success: false, error: { code: 'RATE_LIMITED', message: 'Terlalu banyak permintaan, coba lagi nanti' } },
});
app.use(globalLimiter);

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 50,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: { success: false, error: { code: 'RATE_LIMITED', message: 'Terlalu banyak percobaan, coba 15 menit lagi' } },
});

app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

app.get('/api/health', (_req, res) => {
    res.json({
        success: true,
        data: {
            status: 'ok',
            timestamp: new Date().toISOString(),
        },
    });
});

app.use('/api/v1/auth', authLimiter, authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/sessions', sessionRoutes);
app.use('/api/v1/trainers', trainerRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/reviews', reviewRoutes);
app.use('/api/v1/progress', progressRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/articles', articleRoutes);
app.use('/api/v1/promos', promoRoutes);
app.use('/api/v1/banners', bannerRoutes);
app.use('/api/v1/faqs', faqRoutes);
app.use('/api/v1/reminders', reminderRoutes);
app.use('/api/v1/diet-programs', dietRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/analytics', analyticsRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
