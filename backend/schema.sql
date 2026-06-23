-- ============================================================
-- GymBuddy — PostgreSQL Schema
-- Converted from localhost.sql (MySQL/MariaDB) to PostgreSQL
-- ============================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS diet_programs CASCADE;
DROP TABLE IF EXISTS reminders CASCADE;
DROP TABLE IF EXISTS faq CASCADE;
DROP TABLE IF EXISTS banners CASCADE;
DROP TABLE IF EXISTS promo CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS body_progress CASCADE;
DROP TABLE IF EXISTS progress CASCADE;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS session CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;

-- Drop views
DROP VIEW IF EXISTS customer_booking_history CASCADE;
DROP VIEW IF EXISTS matched_trainer_customer CASCADE;
DROP VIEW IF EXISTS trainer_schedule CASCADE;

-- ============================================================
-- Reusable trigger function for updated_at columns
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- ============================================================
-- TABEL: "user" (menampung semua role: customer, trainer, admin)
-- ============================================================
CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(10) NOT NULL DEFAULT 'customer' CHECK (role IN ('customer','trainer','admin')),
    jenis_kelamin CHAR(1) DEFAULT NULL CHECK (jenis_kelamin IN ('L','P')),
    no_telp VARCHAR(20) DEFAULT NULL,
    tanggal_lahir DATE DEFAULT NULL,
    foto VARCHAR(255) DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    propinsi VARCHAR(45) DEFAULT '',
    kota VARCHAR(45) DEFAULT '',
    spesialisasi VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL
);

CREATE INDEX idx_user_role ON "user" (role);
CREATE INDEX idx_user_kota ON "user" (kota);

CREATE TRIGGER update_user_updated_at BEFORE UPDATE ON "user"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABEL: session (sesi latihan)
-- ============================================================
CREATE TABLE session (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    deskripsi TEXT DEFAULT NULL,
    trainer_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP DEFAULT NULL,
    price NUMERIC(10,2) DEFAULT 0.00,
    status VARCHAR(15) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','ongoing','completed','cancelled')),
    max_participants INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT session_ibfk_trainer FOREIGN KEY (trainer_id) REFERENCES "user" (id) ON UPDATE CASCADE
);

CREATE INDEX idx_session_trainer ON session (trainer_id);
CREATE INDEX idx_session_start_time ON session (start_time);
CREATE INDEX idx_session_trainer_start ON session (trainer_id, start_time);

CREATE TRIGGER update_session_updated_at BEFORE UPDATE ON session
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABEL: booking (pemesanan sesi)
-- ============================================================
CREATE TABLE booking (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Confirmed','Completed','Cancel')),
    payment_status VARCHAR(15) DEFAULT 'pending' CHECK (payment_status IN ('pending','settlement','cancel','expire')),
    payment_method VARCHAR(50) DEFAULT NULL,
    payment_amount NUMERIC(10,2) DEFAULT 0.00,
    payment_date TIMESTAMP DEFAULT NULL,
    midtrans_transaction_id VARCHAR(100) DEFAULT NULL,
    midtrans_order_id VARCHAR(100) DEFAULT NULL,
    midtrans_token TEXT DEFAULT NULL,
    catatan TEXT DEFAULT NULL,
    datetime_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    UNIQUE (session_id, member_id),
    CONSTRAINT booking_ibfk_1 FOREIGN KEY (session_id) REFERENCES session (id),
    CONSTRAINT booking_ibfk_2 FOREIGN KEY (member_id) REFERENCES "user" (id)
);

CREATE INDEX idx_booking_member ON booking (member_id);
CREATE INDEX idx_booking_status ON booking (status);
CREATE INDEX idx_booking_payment_status ON booking (payment_status);

CREATE TRIGGER update_booking_updated_at BEFORE UPDATE ON booking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABEL: progress (progress latihan harian)
-- ============================================================
CREATE TABLE progress (
    id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL,
    booking_id INTEGER DEFAULT NULL,
    activity VARCHAR(100) NOT NULL,
    duration INTEGER NOT NULL,
    note TEXT DEFAULT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT progress_ibfk_1 FOREIGN KEY (member_id) REFERENCES "user" (id),
    CONSTRAINT progress_ibfk_booking FOREIGN KEY (booking_id) REFERENCES booking (id)
);

CREATE INDEX idx_progress_member ON progress (member_id);
CREATE INDEX idx_progress_booking ON progress (booking_id);

-- ============================================================
-- TABEL: body_progress (berat badan, tinggi, BMI, body fat, foto)
-- ============================================================
CREATE TABLE body_progress (
    id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL,
    berat_badan NUMERIC(5,2) DEFAULT NULL,
    tinggi_badan NUMERIC(5,2) DEFAULT NULL,
    bmi NUMERIC(4,2) DEFAULT NULL,
    body_fat NUMERIC(4,1) DEFAULT NULL,
    target_berat NUMERIC(5,2) DEFAULT NULL,
    foto_before VARCHAR(255) DEFAULT NULL,
    foto_after VARCHAR(255) DEFAULT NULL,
    catatan TEXT DEFAULT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT body_progress_ibfk_1 FOREIGN KEY (member_id) REFERENCES "user" (id)
);

CREATE INDEX idx_body_progress_member ON body_progress (member_id);

-- ============================================================
-- TABEL: reviews (rating dan review)
-- ============================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    rating_score SMALLINT NOT NULL CHECK (rating_score BETWEEN 1 AND 5),
    comment TEXT DEFAULT NULL,
    datetime_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_ibfk_1 FOREIGN KEY (session_id) REFERENCES session (id),
    CONSTRAINT reviews_ibfk_2 FOREIGN KEY (member_id) REFERENCES "user" (id)
);

CREATE INDEX idx_reviews_session ON reviews (session_id);
CREATE INDEX idx_reviews_member ON reviews (member_id);
CREATE INDEX idx_reviews_rating ON reviews (rating_score);

-- ============================================================
-- TABEL: notifications (notifikasi in-app)
-- ============================================================
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(15) DEFAULT 'system' CHECK (type IN ('booking','payment','progress','promo','system')),
    is_read SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_ibfk_1 FOREIGN KEY (user_id) REFERENCES "user" (id)
);

CREATE INDEX idx_notifications_user ON notifications (user_id);
CREATE INDEX idx_notifications_is_read ON notifications (is_read);

-- ============================================================
-- TABEL: articles (artikel)
-- ============================================================
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    content TEXT DEFAULT NULL,
    excerpt TEXT DEFAULT NULL,
    kategori VARCHAR(20) DEFAULT 'Workout' CHECK (kategori IN ('Diet','Bulking','Cutting','Workout','Motivasi')),
    author_id INTEGER DEFAULT NULL,
    foto VARCHAR(255) DEFAULT NULL,
    is_published SMALLINT DEFAULT 0,
    published_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT articles_ibfk_1 FOREIGN KEY (author_id) REFERENCES "user" (id)
);

CREATE INDEX idx_articles_kategori ON articles (kategori);
CREATE INDEX idx_articles_author ON articles (author_id);

CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABEL: promo (promo, voucher, diskon)
-- ============================================================
CREATE TABLE promo (
    id SERIAL PRIMARY KEY,
    kode VARCHAR(50) NOT NULL UNIQUE,
    judul VARCHAR(200) NOT NULL,
    deskripsi TEXT DEFAULT NULL,
    tipe VARCHAR(10) DEFAULT 'nominal' CHECK (tipe IN ('persen','nominal')),
    nilai NUMERIC(10,2) NOT NULL,
    min_booking INTEGER DEFAULT 1,
    maks_diskon NUMERIC(10,2) DEFAULT NULL,
    kuota INTEGER DEFAULT NULL,
    terpakai INTEGER DEFAULT 0,
    tanggal_mulai TIMESTAMP DEFAULT NULL,
    tanggal_selesai TIMESTAMP DEFAULT NULL,
    is_active SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABEL: banners (banner halaman utama)
-- ============================================================
CREATE TABLE banners (
    id SERIAL PRIMARY KEY,
    judul VARCHAR(200) DEFAULT NULL,
    deskripsi TEXT DEFAULT NULL,
    gambar VARCHAR(255) NOT NULL,
    link VARCHAR(255) DEFAULT NULL,
    urutan INTEGER DEFAULT 0,
    is_active SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABEL: faq (pertanyaan umum)
-- ============================================================
CREATE TABLE faq (
    id SERIAL PRIMARY KEY,
    pertanyaan TEXT NOT NULL,
    jawaban TEXT NOT NULL,
    kategori VARCHAR(50) DEFAULT 'umum',
    urutan INTEGER DEFAULT 0,
    is_active SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABEL: reminders (pengingat jadwal)
-- ============================================================
CREATE TABLE reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    judul VARCHAR(200) NOT NULL,
    tipe VARCHAR(10) DEFAULT 'latihan' CHECK (tipe IN ('latihan','minum','makan','tidur','custom')),
    waktu TIME DEFAULT NULL,
    hari VARCHAR(50) DEFAULT NULL,
    is_active SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reminders_ibfk_1 FOREIGN KEY (user_id) REFERENCES "user" (id)
);

CREATE INDEX idx_reminders_user ON reminders (user_id);

-- ============================================================
-- TABEL: diet_programs (program diet)
-- ============================================================
CREATE TABLE diet_programs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    tipe VARCHAR(15) NOT NULL CHECK (tipe IN ('bulking','cutting','maintenance')),
    target_kalori INTEGER DEFAULT NULL,
    target_protein INTEGER DEFAULT NULL,
    target_karbohidrat INTEGER DEFAULT NULL,
    target_lemak INTEGER DEFAULT NULL,
    tanggal_mulai DATE DEFAULT NULL,
    tanggal_selesai DATE DEFAULT NULL,
    is_active SMALLINT DEFAULT 1,
    catatan TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT diet_programs_ibfk_1 FOREIGN KEY (user_id) REFERENCES "user" (id)
);

CREATE INDEX idx_diet_programs_user ON diet_programs (user_id);

CREATE TRIGGER update_diet_programs_updated_at BEFORE UPDATE ON diet_programs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SEED DATA: Admin default
-- ============================================================
INSERT INTO "user" (nama, email, password, role, jenis_kelamin, no_telp, kota, spesialisasi, bio) VALUES
('Admin GymBuddy', 'admin@gmail.com', '$2b$10$8U5ecdrkOX6RpJ04X.E4LOV7VZDEVvtjzyFG1GHv20dVEGjbYHPDS', 'admin', 'L', '081234567890', 'Purwokerto', NULL, 'Admin Platform GymBuddy'),
('Fadhel Setiawan', 'fadhel@gmail.com', '$2b$10$doLA4P.QxJoB6u.X2aY7Z..Ld1TrWYFd0pn.Vs1Xu7Il3Fqyw1/wm', 'trainer', 'L', '081234567893', 'Purwokerto', 'Hypertrophy Coach', 'Spesialis pembentukan otot dan program hypertrophy untuk hasil maksimal'),
('Arif Rachman', 'arif@gmail.com', '$2b$10$doLA4P.QxJoB6u.X2aY7Z..Ld1TrWYFd0pn.Vs1Xu7Il3Fqyw1/wm', 'trainer', 'L', '081234567894', 'Purwokerto', 'Lose Weight Coach', 'Ahli program penurunan berat badan dengan pendekatan ilmiah dan terukur'),
('Gusti Caesar Yuliawan', 'gusti@gmail.com', '$2b$10$doLA4P.QxJoB6u.X2aY7Z..Ld1TrWYFd0pn.Vs1Xu7Il3Fqyw1/wm', 'trainer', 'L', '081234567895', 'Purwokerto', 'Strength Coach', 'Pelatih strength training profesional dengan pengalaman lebih dari 5 tahun'),
('Siti Rahmawati', 'user@gmail.com', '$2b$10$GtJBBDGfoRkW3JdlF6AY.ufoZcWfv/FMwW1zV3Uk/4oy5ZKdTbQai', 'customer', 'P', '081234567892', 'Purwokerto', NULL, 'Member GymBuddy');

-- ============================================================
-- SEED DATA: FAQ default
-- ============================================================
INSERT INTO faq (pertanyaan, jawaban, kategori, urutan) VALUES
('Bagaimana cara memesan personal trainer?', 'Anda bisa login ke akun, lalu pilih menu "Cari Trainer", pilih trainer yang diinginkan, dan klik "Ambil Sesi".', 'booking', 1),
('Bagaimana cara membatalkan booking?', 'Anda bisa membatalkan booking di menu "Booking Saya" selama status masih "Pending".', 'booking', 2),
('Apa saja metode pembayaran yang tersedia?', 'Kami menerima pembayaran melalui GoPay, OVO, DANA, Bank Transfer, dan Kartu Kredit melalui Midtrans.', 'pembayaran', 3),
('Bagaimana cara menjadi trainer?', 'Silakan daftar dengan memilih role "Trainer" pada halaman registrasi. Admin akan memverifikasi akun Anda.', 'akun', 4);

-- ============================================================
-- SEED DATA: Artikel default
-- ============================================================
INSERT INTO articles (title, slug, content, excerpt, kategori, is_published, published_at) VALUES
('Panduan Bulking untuk Pemula', 'panduan-bulking-pemula', 'Bulking adalah fase menambah massa otot dengan cara meningkatkan asupan kalori...', 'Panduan lengkap bulking untuk pemula yang ingin membentuk otot.', 'Bulking', 1, NOW()),
('Tips Cutting yang Efektif', 'tips-cutting-efektif', 'Cutting adalah fase membakar lemak sambil mempertahankan massa otot...', 'Tips cutting yang efektif untuk mendapatkan body goals.', 'Cutting', 1, NOW()),
('5 Gerakan Workout Terbaik', '5-gerakan-workout-terbaik', 'Berikut adalah 5 gerakan workout terbaik yang wajib Anda coba...', 'Gerakan workout terbaik untuk hasil maksimal.', 'Workout', 1, NOW());

-- ============================================================
-- SEED DATA: Promo default
-- ============================================================
INSERT INTO promo (kode, judul, deskripsi, tipe, nilai, min_booking, is_active) VALUES
('WELCOME10', 'Diskon Member Baru', 'Diskon 10% untuk booking pertama Anda', 'persen', 10.00, 1, 1),
('FREEPASS', 'Free Session', 'Gratis 1 sesi untuk setiap 5 booking', 'nominal', 50000.00, 5, 1);

-- ============================================================
-- SEED DATA: Sample sessions
-- ============================================================
INSERT INTO session (title, deskripsi, trainer_id, start_time, end_time, price, status, max_participants) VALUES
('Private Gym Training', 'Sesi latihan pribadi 1-on-1 dengan trainer profesional. Cocok untuk pemula maupun lanjutan.', 2, NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day' + INTERVAL '1 hour', 75000.00, 'scheduled', 1),
('Yoga & Fleksibilitas', 'Latihan yoga untuk meningkatkan fleksibilitas dan kekuatan inti tubuh.', 2, NOW() + INTERVAL '3 days', NOW() + INTERVAL '3 days' + INTERVAL '1 hour', 50000.00, 'scheduled', 5),
('Hypertrophy Program', 'Program hypertrophy intensif untuk membangun massa otot maksimal. Cocok untuk intermediate hingga advanced.', 3, NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days' + INTERVAL '1 hour', 100000.00, 'scheduled', 1),
('Arms & Shoulders Day', 'Fokus pada pembentukan lengan dan bahu dengan teknik isolasi terbaik.', 3, NOW() + INTERVAL '4 days', NOW() + INTERVAL '4 days' + INTERVAL '1 hour', 85000.00, 'scheduled', 1),
('Weight Loss Bootcamp', 'Program penurunan berat badan intensif dengan HIIT dan cardio terstruktur.', 4, NOW() + INTERVAL '1 day' + INTERVAL '2 hours', NOW() + INTERVAL '1 day' + INTERVAL '3 hours', 90000.00, 'scheduled', 5),
('Fat Burning Circuit', 'Latihan sirkuit pembakaran lemak full-body. Efektif untuk menurunkan berat badan.', 4, NOW() + INTERVAL '5 days', NOW() + INTERVAL '5 days' + INTERVAL '1 hour', 80000.00, 'scheduled', 3),
('Strength Foundation', 'Program dasar strength training untuk membangun kekuatan fundamental.', 5, NOW() + INTERVAL '3 days' + INTERVAL '2 hours', NOW() + INTERVAL '3 days' + INTERVAL '3 hours', 95000.00, 'scheduled', 1),
('Powerlifting Prep', 'Persiapan teknik powerlifting: squat, bench press, deadlift dengan koreksi form detail.', 5, NOW() + INTERVAL '6 days', NOW() + INTERVAL '6 days' + INTERVAL '2 hours', 120000.00, 'scheduled', 1);

-- ============================================================
-- VIEWS
-- ============================================================

CREATE OR REPLACE VIEW customer_booking_history AS
SELECT b.id AS booking_id, s.title AS session_title, s.start_time, s.end_time,
       u.nama AS customer_name, u.id AS customer_id,
       tr.nama AS trainer_name, b.status, b.datetime_created AS booked_on
FROM booking b
JOIN session s ON b.session_id = s.id
JOIN "user" u ON b.member_id = u.id
JOIN "user" tr ON s.trainer_id = tr.id
ORDER BY b.datetime_created DESC;

CREATE OR REPLACE VIEW matched_trainer_customer AS
SELECT b.id AS booking_id, s.id AS session_id, s.title AS session_title, s.start_time,
       tr.id AS trainer_id, tr.nama AS trainer_name, tr.email AS trainer_email,
       u.id AS customer_id, u.nama AS customer_name, u.email AS customer_email,
       b.status, b.datetime_created
FROM booking b
JOIN session s ON b.session_id = s.id
JOIN "user" tr ON s.trainer_id = tr.id
JOIN "user" u ON b.member_id = u.id
WHERE b.status = 'Confirmed';

CREATE OR REPLACE VIEW trainer_schedule AS
SELECT s.*, tr.nama AS trainer_name,
    (SELECT COUNT(*) FROM booking b WHERE b.session_id = s.id AND b.status = 'Confirmed') AS confirmed_customers
FROM session s
JOIN "user" tr ON s.trainer_id = tr.id
WHERE tr.role = 'trainer'
ORDER BY s.start_time ASC;
