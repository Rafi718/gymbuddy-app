import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export function signToken(payload: { id: number; role: string }): string {
    return jwt.sign(payload, env.JWT_SECRET, { expiresIn: '7d' });
}

export function verifyToken(token: string): { id: number; role: string } | null {
    try {
        return jwt.verify(token, env.JWT_SECRET) as { id: number; role: string };
    } catch {
        return null;
    }
}
