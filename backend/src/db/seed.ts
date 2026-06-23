import bcrypt from 'bcrypt';
import { db, closeDB } from './client';
import { users, sessions, faq, articles, promo, banners } from './schema';
import { logger } from '../utils/logger';

async function seed() {
    logger.info('[SEED] Starting database seed...');

    // Hash passwords
    const adminHash = await bcrypt.hash('admin123', 10);
    const trainerHash = await bcrypt.hash('trainer123', 10);
    const userHash = await bcrypt.hash('user123', 10);

    // Users
    const insertedUsers = await db.insert(users).values([
        { nama: 'Admin GymBuddy', email: 'admin@gmail.com', password: adminHash, role: 'admin', propinsi: 'Jawa Tengah', kota: 'Purwokerto' },
        { nama: 'Fadhel Trainer', email: 'fadhel@gmail.com', password: trainerHash, role: 'trainer', propinsi: 'Jawa Tengah', kota: 'Purwokerto', spesialisasi: 'Body Building', bio: 'Personal trainer bersertifikat dengan 5 tahun pengalaman.' },
        { nama: 'Arif Trainer', email: 'arif@gmail.com', password: trainerHash, role: 'trainer', propinsi: 'Jawa Tengah', kota: 'Purwokerto', spesialisasi: 'Calisthenics', bio: 'Spesialis calisthenics dan functional training.' },
        { nama: 'Gusti Trainer', email: 'gusti@gmail.com', password: trainerHash, role: 'trainer', propinsi: 'Jawa Tengah', kota: 'Purwokerto', spesialisasi: 'Powerlifting', bio: 'Powerlifting coach dengan rekam jejak kompetisi nasional.' },
        { nama: 'User Member', email: 'user@gmail.com', password: userHash, role: 'customer', propinsi: 'Jawa Tengah', kota: 'Purwokerto' },
    ]).returning();
    logger.info({ count: insertedUsers.length }, '[SEED] Users inserted');

    const trainerIds = insertedUsers.filter((u) => u.role === 'trainer').map((u) => u.id);

    // Sessions
    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const insertedSessions = await db.insert(sessions).values([
        { title: 'Body Building Beginner', description: 'Sesi latihan body building untuk pemula', trainer_id: trainerIds[0], start_time: tomorrow, end_time: new Date(tomorrow.getTime() + 60 * 60 * 1000), price: '150000.00', max_participants: 5 },
        { title: 'Calisthenics Fundamentals', description: 'Latihan calisthenics dasar untuk semua level', trainer_id: trainerIds[1], start_time: nextWeek, end_time: new Date(nextWeek.getTime() + 90 * 60 * 60 * 1000), price: '100000.00', max_participants: 8 },
        { title: 'Powerlifting Technique', description: 'Teknik dasar powerlifting: squat, bench, deadlift', trainer_id: trainerIds[2], start_time: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000), end_time: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000 + 120 * 60 * 1000), price: '200000.00', max_participants: 3 },
    ]).returning();
    logger.info({ count: insertedSessions.length }, '[SEED] Sessions inserted');

    // FAQ
    const insertedFaq = await db.insert(faq).values([
        { pertanyaan: 'Bagaimana cara mendaftar sebagai member?', jawaban: 'Klik tombol Daftar di halaman utama, isi data diri, lalu login dengan akun yang sudah dibuat.', kategori: 'umum', urutan: 1 },
        { pertanyaan: 'Bagaimana cara booking sesi latihan?', jawaban: 'Setelah login, pilih menu Cari Trainer, pilih sesi yang diinginkan, lalu klik Ambil Sesi.', kategori: 'booking', urutan: 2 },
        { pertanyaan: 'Metode pembayaran apa saja yang didukung?', jawaban: 'Kami mendukung pembayaran via Midtrans: kartu kredit, transfer bank, dan e-wallet (GoPay, OVO, DANA).', kategori: 'pembayaran', urutan: 3 },
        { pertanyaan: 'Apakah saya bisa membatalkan booking?', jawaban: 'Ya, Anda dapat membatalkan booking selama status masih pending. Hubungi admin untuk pembatalan setelah confirmed.', kategori: 'booking', urutan: 4 },
        { pertanyaan: 'Bagaimana cara menjadi trainer di GymBuddy?', jawaban: 'Daftar dengan memilih role Trainer saat registrasi. Lengkapi profil dengan spesialisasi dan bio Anda.', kategori: 'umum', urutan: 5 },
    ]).returning();
    logger.info({ count: insertedFaq.length }, '[SEED] FAQ inserted');

    // Articles
    const insertedArticles = await db.insert(articles).values([
        { title: '5 Latihan untuk Membangun Otot Dada', slug: '5-latihan-otot-dada', content: 'Push-up, bench press, dumbbell fly, incline press, dan cable crossover adalah 5 latihan terbaik untuk membangun otot dada...', excerpt: 'Panduan lengkap 5 latihan terbaik untuk otot dada.', kategori: 'Workout', author_id: insertedUsers[0].id, is_published: true, published_at: now },
        { title: 'Diet Bulking untuk Pemula', slug: 'diet-bulking-pemula', content: 'Bulking adalah fase meningkatkan massa otot dengan surplus kalori...', excerpt: 'Tips diet bulking untuk pemula yang aman dan efektif.', kategori: 'Bulking', author_id: insertedUsers[0].id, is_published: true, published_at: now },
        { title: 'Motivasi Fitness: Konsistensi adalah Kunci', slug: 'motivasi-fitness-konsistensi', content: 'Banyak orang mulai gym dengan semangat tinggi tapi cepat menyerah...', excerpt: 'Cara menjaga konsistensi dalam fitness.', kategori: 'Motivasi', author_id: insertedUsers[0].id, is_published: true, published_at: now },
    ]).returning();
    logger.info({ count: insertedArticles.length }, '[SEED] Articles inserted');

    // Promo
    const insertedPromo = await db.insert(promo).values([
        { kode: 'HEMAT50', judul: 'Diskon Rp 50.000', deskripsi: 'Potongan Rp 50.000 untuk booking pertama', tipe: 'nominal', nilai: '50000.00', min_booking: 1, kuota: 100, tanggal_mulai: now, tanggal_selesai: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000) },
        { kode: 'HEMAT20', judul: 'Diskon 20%', deskripsi: 'Potongan 20% maksimal Rp 25.000', tipe: 'persen', nilai: '20.00', min_booking: 1, maks_diskon: '25000.00', kuota: 50, tanggal_mulai: now, tanggal_selesai: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000) },
    ]).returning();
    logger.info({ count: insertedPromo.length }, '[SEED] Promo inserted');

    // Banners
    const insertedBanners = await db.insert(banners).values([
        { judul: 'Temukan Trainer Terbaik di Purwokerto', deskripsi: 'Gabung GymBuddy sekarang dan dapatkan sesi latihan pertama dengan diskon spesial!', gambar: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1200', link: '/register', urutan: 1 },
        { judul: 'Promo Bulan Ini', deskripsi: 'Gunakan kode HEMAT50 untuk diskon Rp 50.000!', gambar: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200', link: '/promo', urutan: 2 },
    ]).returning();
    logger.info({ count: insertedBanners.length }, '[SEED] Banners inserted');

    logger.info('[SEED] Database seed completed successfully!');
    await closeDB();
    process.exit(0);
}

seed().catch((err) => {
    logger.error({ err }, '[SEED] Seed failed');
    process.exit(1);
});
