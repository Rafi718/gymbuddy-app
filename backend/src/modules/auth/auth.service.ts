import bcrypt from 'bcrypt';
import crypto from 'crypto';
import NodeCache from 'node-cache';
import { findUserByEmail, findUserById, createUser, updatePassword, updateUserVerified } from './auth.repo';
import { signToken } from '../../utils/jwt';
import { sendOtpEmail, sendResetPasswordOtpEmail } from '../../utils/emailService';

// Token store: key = token, value = { userId, email }, TTL = 15 minutes
const resetTokenCache = new NodeCache({ stdTTL: 900, checkperiod: 120 });

// OTP store: key = email, value = { otp, userId, nama, attempts }, TTL = 5 minutes
const otpCache = new NodeCache({ stdTTL: 300, checkperiod: 60 });

// Password reset OTP store: key = email, value = { otp, userId, nama, attempts }, TTL = 5 minutes
const resetOtpCache = new NodeCache({ stdTTL: 300, checkperiod: 60 });

function generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

export class AuthError extends Error {
    constructor(
        public statusCode: number,
        public code: string,
        message: string,
    ) {
        super(message);
    }
}

export async function registerCustomer(data: {
    nama: string;
    email: string;
    password: string;
    jenis_kelamin?: string;
    no_telp?: string;
    tanggal_lahir?: string;
    propinsi?: string;
    kota?: string;
}) {
    console.log('[REGISTER]', data.email);
    const existing = await findUserByEmail(data.email);
    console.log('[REGISTER] existing user:', existing ? existing.id : null);
    if (existing) {
        throw new AuthError(409, 'CONFLICT', 'Email sudah digunakan');
    }

    const hashed = await bcrypt.hash(data.password, 10);
    const user = await createUser({
        nama: data.nama,
        email: data.email,
        password: hashed,
        role: 'customer',
        jenis_kelamin: data.jenis_kelamin,
        no_telp: data.no_telp,
        tanggal_lahir: data.tanggal_lahir,
        propinsi: data.propinsi,
        kota: data.kota,
    });

    // Generate and send OTP
    const otp = generateOtp();
    otpCache.set(data.email, { otp, userId: user.id, nama: user.nama, attempts: 0 });
    console.log('[REGISTER] created user id:', user.id, 'email:', data.email, 'otp:', otp);
    await sendOtpEmail(data.email, otp, user.nama);

    return { message: 'Pendaftaran berhasil. Silakan cek email Anda untuk kode OTP verifikasi.', email: data.email };
}

export async function registerTrainer(data: {
    nama: string;
    email: string;
    password: string;
    spesialisasi: string;
    bio?: string;
    no_telp?: string;
    propinsi?: string;
    kota?: string;
}) {
    const existing = await findUserByEmail(data.email);
    if (existing) {
        throw new AuthError(409, 'CONFLICT', 'Email sudah digunakan');
    }

    const hashed = await bcrypt.hash(data.password, 10);
    const user = await createUser({
        nama: data.nama,
        email: data.email,
        password: hashed,
        role: 'trainer',
        spesialisasi: data.spesialisasi,
        bio: data.bio,
        no_telp: data.no_telp,
        propinsi: data.propinsi,
        kota: data.kota,
    });

    // Generate and send OTP
    const otp = generateOtp();
    otpCache.set(data.email, { otp, userId: user.id, nama: user.nama, attempts: 0 });
    await sendOtpEmail(data.email, otp, user.nama);

    return { message: 'Pendaftaran berhasil. Silakan cek email Anda untuk kode OTP verifikasi.', email: data.email };
}

export async function registerAdmin(data: { nama: string; email: string; password: string }) {
    const existing = await findUserByEmail(data.email);
    if (existing) {
        throw new AuthError(409, 'CONFLICT', 'Email sudah digunakan');
    }

    const hashed = await bcrypt.hash(data.password, 10);
    const user = await createUser({
        nama: data.nama,
        email: data.email,
        password: hashed,
        role: 'admin',
    });

    const token = signToken({ id: user.id, role: user.role });
    return { user: sanitizeUser(user), token };
}

export async function login(email: string, password: string) {
    console.log('[LOGIN] attempt:', email);
    const user = await findUserByEmail(email);
    console.log('[LOGIN] user found:', user ? user.id : null);
    if (!user) {
        throw new AuthError(401, 'UNAUTHORIZED', 'Email atau password salah');
    }

    const valid = await bcrypt.compare(password, user.password);
    console.log('[LOGIN] password valid:', valid, 'is_verified:', user.is_verified, 'role:', user.role);
    if (!valid) {
        throw new AuthError(401, 'UNAUTHORIZED', 'Email atau password salah');
    }

    if (!user.is_verified) {
        // Resend OTP automatically
        const otp = generateOtp();
        otpCache.set(email, { otp, userId: user.id, nama: user.nama, attempts: 0 });
        try {
            await sendOtpEmail(email, otp, user.nama);
        } catch { /* ignore email errors */ }
        throw new AuthError(403, 'EMAIL_NOT_VERIFIED', 'Email belum diverifikasi. Kode OTP baru telah dikirim ke email Anda.');
    }

    const token = signToken({ id: user.id, role: user.role });
    return { user: sanitizeUser(user), token };
}

export async function getMe(userId: number) {
    const user = await findUserById(userId);
    if (!user) {
        throw new AuthError(404, 'NOT_FOUND', 'User tidak ditemukan');
    }
    return sanitizeUser(user);
}

export async function forgotPassword(email: string) {
    const user = await findUserByEmail(email);
    if (!user) {
        throw new AuthError(404, 'NOT_FOUND', 'Email tidak terdaftar');
    }

    // Generate OTP and send to email
    const otp = generateOtp();
    resetOtpCache.set(email, { otp, userId: user.id, nama: user.nama, attempts: 0 });
    await sendResetPasswordOtpEmail(email, otp, user.nama);

    return { message: 'Kode OTP reset password telah dikirim ke email Anda.', email };
}

export async function resetPassword(email: string, otp: string, newPassword: string) {
    const stored = resetOtpCache.get<{ otp: string; userId: number; nama: string; attempts: number }>(email);
    if (!stored) {
        throw new AuthError(400, 'OTP_EXPIRED', 'Kode OTP tidak ditemukan atau sudah kedaluwarsa. Silakan minta kode baru.');
    }

    if (stored.attempts >= 5) {
        resetOtpCache.del(email);
        throw new AuthError(429, 'TOO_MANY_ATTEMPTS', 'Terlalu banyak percobaan salah. Silakan minta kode baru.');
    }

    if (stored.otp !== otp) {
        stored.attempts++;
        resetOtpCache.set(email, stored);
        throw new AuthError(400, 'OTP_INVALID', `Kode OTP salah. Percobaan tersisa: ${5 - stored.attempts}`);
    }

    const hashed = await bcrypt.hash(newPassword, 10);
    const updated = await updatePassword(stored.userId, hashed);
    if (!updated) {
        throw new AuthError(404, 'NOT_FOUND', 'User tidak ditemukan');
    }

    // Hapus OTP setelah digunakan
    resetOtpCache.del(email);

    return { message: 'Password berhasil diubah. Silakan login dengan password baru.' };
}

export async function verifyOtp(email: string, otp: string) {
    console.log('[VERIFY OTP] email:', email, 'otp:', otp);
    const stored = otpCache.get<{ otp: string; userId: number; nama: string; attempts: number }>(email);
    if (!stored) {
        throw new AuthError(400, 'OTP_EXPIRED', 'Kode OTP tidak ditemukan atau sudah kedaluwarsa. Silakan minta kode baru.');
    }

    if (stored.attempts >= 5) {
        otpCache.del(email);
        throw new AuthError(429, 'TOO_MANY_ATTEMPTS', 'Terlalu banyak percobaan salah. Silakan minta kode baru.');
    }

    if (stored.otp !== otp) {
        stored.attempts++;
        otpCache.set(email, stored);
        console.log('[VERIFY OTP] wrong. expected:', stored.otp, 'got:', otp, 'attempts:', stored.attempts);
        throw new AuthError(400, 'OTP_INVALID', `Kode OTP salah. Percobaan tersisa: ${5 - stored.attempts}`);
    }

    // OTP correct — verify user
    await updateUserVerified(stored.userId);
    otpCache.del(email);
    console.log('[VERIFY OTP] success. userId:', stored.userId);

    return { message: 'Email berhasil diverifikasi. Silakan login.' };
}

export async function resendOtp(email: string) {
    const user = await findUserByEmail(email);
    if (!user) {
        throw new AuthError(404, 'NOT_FOUND', 'Email tidak terdaftar');
    }

    if (user.is_verified) {
        throw new AuthError(400, 'ALREADY_VERIFIED', 'Email sudah diverifikasi');
    }

    const otp = generateOtp();
    otpCache.set(email, { otp, userId: user.id, nama: user.nama, attempts: 0 });
    await sendOtpEmail(email, otp, user.nama);

    return { message: 'Kode OTP baru telah dikirim ke email Anda.' };
}

function sanitizeUser(user: any) {
    const { password, ...rest } = user;
    return rest;
}
