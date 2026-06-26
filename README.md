# 🏋️ GymBuddy — Platform Fitness Purwokerto

## 📋 Daftar Isi
1. [Tentang Aplikasi](#-tentang-aplikasi)
2. [Tech Stack & Arsitektur](#-tech-stack--arsitektur)
3. [Cara Menjalankan Aplikasi](#-cara-menjalankan-aplikasi)
4. [Cara Menggunakan](#-cara-menggunakan)
5. [Akun & Password](#-akun--password)
6. [Fitur Lengkap](#-fitur-lengkap)
7. [Struktur Project](#-struktur-project)
8. [API Endpoints](#-api-endpoints)
9. [Environment Variables](#-environment-variables)
10. [Deployment](#-deployment)
11. [Build Mobile (APK / IPA)](#-build-mobile-apk--ipa)

---

## 🎯 Tentang Aplikasi

**GymBuddy** adalah platform fitness yang menghubungkan **personal trainer** dengan **member** di area **Purwokerto** dan sekitarnya. Aplikasi ini memudahkan pengguna untuk:

- **Mencari personal trainer** berdasarkan lokasi dan keahlian
- **Booking sesi latihan** secara online
- **Melakukan pembayaran** via Midtrans (kartu kredit, transfer bank, e-wallet, dll)
- **Melacak progress** latihan & body progress
- **Mengelola jadwal** bagi trainer
- **Verifikasi email via OTP** saat registrasi & reset password

Aplikasi tersedia dalam 3 platform:
- 🌐 **Website** — Frontend Vue 3 di Cloudflare Pages (`gymbuddy.site`)
- 📱 **Mobile App** — Flutter (iOS & Android)
- ⚙️ **Backend API** — Node.js + Express + Drizzle ORM (`api.gymbuddy.site`)

---

## 🛠 Tech Stack & Arsitektur

### Arsitektur 3-Tier (Full Stack)

```
[Frontend Web] ──── HTTP/JSON ──── [Backend API] ──── SQL ──── [Database]
[Mobile App]  ──── HTTP/JSON ────  [Node.js/Express] ────  [PostgreSQL/Neon]
```

### Teknologi yang Digunakan

| Layer | Teknologi | Versi |
|-------|-----------|-------|
| **Frontend Web** | Vue 3 + Vite + Tailwind CSS + Pinia | Vue 3.5, Vite 8 |
| **Mobile App** | Flutter + Riverpod + GoRouter + Dio | Flutter 3.x (Dart 3.12) |
| **Backend API** | Node.js + Express 5 + Drizzle ORM + Zod | Node 20+ |
| **Database** | PostgreSQL (Neon Cloud) | PostgreSQL 16 |
| **ORM** | Drizzle ORM + drizzle-kit | 0.45.x |
| **Payment** | Midtrans Snap (Sandbox/Production) | midtrans-client 1.4 |
| **Email** | Resend (transactional email) | resend 6.x |
| **Auth** | JWT (7 hari) + bcrypt + OTP (NodeCache) | jsonwebtoken 9 |
| **Hosting Web** | Cloudflare Pages | `gymbuddy.site` |
| **Hosting API** | Railway / Render | `api.gymbuddy.site` |
| **File Upload** | Multer (local storage `uploads/profiles/`) | multer 2.x |
| **Caching** | NodeCache (in-memory, untuk OTP) | node-cache 5.x |
| **Logging** | Pino + pino-http | pino 10.x |
| **Security** | Helmet, CORS, express-rate-limit | helmet 8, rate-limit 8 |

### Package Penting (Backend)
- `express` 5 — Web framework
- `drizzle-orm` + `pg` — PostgreSQL ORM & driver
- `bcrypt` — Hash password (salt rounds 10)
- `jsonwebtoken` — JWT auth (expiry 7 hari)
- `midtrans-client` — Payment gateway
- `multer` — File upload (foto profil)
- `resend` — Email service untuk OTP
- `node-cache` — In-memory cache untuk OTP (TTL 5 menit)
- `zod` — Schema validation
- `helmet`, `compression`, `express-rate-limit` — Security & performance
- `pino`, `pino-http` — Structured logging

### Package Penting (Frontend Web)
- `vue` 3.5 + `vue-router` 5 — Framework & routing
- `pinia` 3 — State management (auth store)
- `axios` — HTTP client (interceptor attach token + handle 401)
- `lucide-vue-next` — Icon library
- `tailwindcss` 3.4 — Styling

### Package Penting (Mobile/Flutter)
- `flutter_riverpod` 2.6 — State management (AuthNotifier)
- `go_router` 14.8 — Routing & navigasi (dengan redirect guard)
- `dio` 5.7 — HTTP client (interceptor attach token + handle 401)
- `shared_preferences` 2.3 — Simpan token lokal
- `cached_network_image` 3.4 — Load & cache gambar
- `image_picker` 1.1 — Upload foto profil
- `url_launcher` 6.3 — Buka link payment
- `flutter_inappwebview` 6.1 — Midtrans payment WebView
- `intl` 0.20 — Format tanggal & mata uang
- `fluttertoast` 9.1 — Toast notification
- `flutter_launcher_icons` 0.14 — Generate app icon dari logo

---

## 🚀 Cara Menjalankan Aplikasi

### Prasyarat
- **Node.js** v20 atau lebih baru (backend butuh `>=20`)
- **Flutter SDK** 3.x (Dart 3.12+) atau lebih baru
- **PostgreSQL** (local atau cloud — Neon/Aiven/Railway)
- **Android Studio** (untuk Android emulator/device)
- **Xcode** (untuk iOS simulator, macOS only)
- **Git**

### 1. Clone Repository

```bash
git clone https://github.com/arif200/gymbuddy-app.git
cd gymbuddy-app
```

### 2. Setup Backend

```bash
cd backend
npm install
```

Buat file `.env` di folder `backend/` (lihat [Environment Variables](#-environment-variables) untuk detail lengkap):

```env
# Database — PostgreSQL (Neon / Railway / local)
DATABASE_URL=postgresql://user:password@host/database?sslmode=require

# JWT
JWT_SECRET=your-secret-key-change-in-production

# Server
PORT=5000
NODE_ENV=development

# Frontend URL (untuk CORS)
FRONTEND_URL=http://localhost:5173

# Email (Resend) — untuk OTP verifikasi & reset password
RESEND_API_KEY=re_your_api_key
EMAIL_FROM=GymBuddy <noreply@notif.gymbuddy.site>

# Midtrans (Sandbox untuk development)
MIDTRANS_SERVER_KEY=SB-Mid-server-your-key
MIDTRANS_CLIENT_KEY=SB-Mid-client-your-key
MIDTRANS_IS_PRODUCTION=false
```

Jalankan migrasi database (jika pertama kali):

```bash
npm run db:generate    # Generate migration dari schema Drizzle
npm run db:migrate     # Jalankan migrasi
npm run db:seed        # (Opsional) Seed data awal
```

Jalankan backend:

```bash
npm run dev            # Development (nodemon + tsx, auto-reload)
# atau
npm start              # Production (tsx)
```

Backend akan berjalan di `http://localhost:5000`.
Health check: `GET http://localhost:5000/api/health`

### 3. Setup Frontend Web

```bash
cd frontend
npm install
```

Buat file `.env` di folder `frontend/`:

```env
VITE_API_URL=http://localhost:5000/api/v1
```

> Jika `VITE_API_URL` tidak diset, frontend otomatis pakai:
> - `http://localhost:5000/api/v1` saat di localhost
> - `https://api.gymbuddy.site/api/v1` saat di production

Jalankan frontend:

```bash
npm run dev            # Development (Vite, port 5173)
npm run build          # Build production (output: dist/)
npm run preview        # Preview build production
```

Frontend akan berjalan di `http://localhost:5173`.

### 4. Setup Mobile App

```bash
cd mobile
flutter pub get
```

Konfigurasi API URL ada di `lib/services/api_service.dart`:
```dart
static const String _prodUrl = 'https://api.gymbuddy.site/api/v1';
static const String _devUrl = 'http://10.0.2.2:5000/api/v1';  // 10.0.2.2 = host loopback dari Android emulator
static const bool _isProduction = true;
```

> Untuk development lokal, ubah `_isProduction = false` agar pakai `_devUrl`.
> `10.0.2.2` adalah alias ke `localhost` dari dalam Android emulator.

Generate app icon (jika logo berubah):

```bash
dart run flutter_launcher_icons
```

Jalankan di device/emulator:

```bash
flutter run                                    # Device default
flutter run -d emulator-5554                   # Android emulator spesifik
flutter run -d simulator                       # iOS simulator
```

---

## 📖 Cara Menggunakan

### Untuk Member (Pengguna Biasa)

#### 1. Registrasi & Verifikasi Email
1. Buka aplikasi/web → klik **"Daftar"** / **"Register"**
2. Isi form registrasi:
   - **Website**: Nama, Email, Password, Provinsi, Kota, Daftar Sebagai (Member/Trainer), Spesialisasi (jika Trainer)
   - **Mobile**: Nama, Email, Password, Konfirmasi Password, Provinsi, Kota (customer only)
3. Klik **"Daftar"** → kode OTP dikirim ke email
4. Buka halaman **Verifikasi OTP**, masukkan 6 digit kode
5. Setelah terverifikasi → login dengan email & password

#### 2. Login
1. Masukkan email & password
2. Jika email belum diverifikasi → sistem auto-kirim OTP baru & redirect ke halaman verifikasi
3. Jika sudah diverifikasi → masuk ke dashboard

#### 3. Lupa Password
1. Klik **"Lupa Password?"** di halaman login
2. Masukkan email terdaftar → kode OTP dikirim ke email
3. Buka halaman **Reset Password**, masukkan OTP + password baru + konfirmasi
4. Login dengan password baru
5. Tombol **"Kirim ulang OTP"** tersedia dengan cooldown 60 detik

#### 4. Cari Trainer & Booking
1. Setelah login, buka menu **"Cari Trainer"** / **"Find Trainers"**
2. Lihat daftar sesi yang tersedia (dilengkapi foto trainer)
3. Klik **"Ambil Sesi"** / **"Booking"** untuk booking
4. Booking akan muncul di menu **"Booking Saya"** / **"My Bookings"**

#### 5. Pembayaran
1. Di menu **"Booking Saya"**, klik **"Bayar"**
2. Klik **"Bayar Sekarang via Midtrans"**
3. Pilih metode pembayaran:
   - **Kartu Kredit** (test: `4811 1111 1111 1114`, exp: kapan saja, CVV: apapun)
   - **Bank Transfer** (BCA, Mandiri, BRI, dll)
   - **E-Wallet** (GoPay, OVO, DANA, dll)
4. Selesaikan pembayaran
5. Status booking berubah menjadi **"Confirmed / LUNAS"**

#### 6. Profil & Progress
1. Klik ikon **profil** → lihat data diri & role badge
2. Klik **edit** untuk ubah profil
3. Klik ikon **kamera** untuk upload foto profil
4. Catat progress latihan harian & body progress

### Untuk Trainer (Website only — mobile khusus customer)
1. Daftar sebagai Trainer di website
2. Login di website → dashboard trainer muncul
3. Kelola sesi latihan (CRUD)
4. Lihat daftar client yang booking
5. Edit profil trainer

### Untuk Admin (Website only)
1. Login sebagai admin (`admin@gmail.com` / `admin123`)
2. Dashboard admin dengan statistik lengkap
3. **Kelola Users** — Lihat, cari, hapus user
4. **Kelola Trainer** — Daftar trainer terdaftar
5. **Kelola Booking** — Semua booking & status pembayaran
6. **Kelola Artikel** — Buat, edit, hapus artikel fitness
7. **Kelola Promo/Voucher** — Buat kode promo dengan diskon
8. **Kelola FAQ** — Atur pertanyaan umum
9. **Kelola Banner** — CRUD banner landing page
10. **Kelola Notifikasi** — Kirim notifikasi ke user

---

## 🔑 Akun & Password

### Akun Test

| Role | Email | Password |
|------|-------|----------|
| **👤 Member** | `user@gmail.com` | `user123` |
| **🏋️ Trainer 1** | `fadhel@gmail.com` | `trainer123` |
| **🏋️ Trainer 2** | `arif@gmail.com` | `trainer123` |
| **🏋️ Trainer 3** | `gusti@gmail.com` | `trainer123` |
| **🛠️ Admin** | `admin@gmail.com` | `admin123` |

> **Catatan:** Akun test harus sudah `is_verified=true` di database. Jika belum, login akan ditolak dengan error `EMAIL_NOT_VERIFIED` dan OTP baru akan dikirim otomatis.

### Kartu Kredit Test Midtrans (Sandbox)

| Provider | Nomor Kartu | CVV | Expiry |
|----------|-------------|-----|--------|
| **Visa** | `4811 1111 1111 1114` | Apa saja | Masa depan |
| **Visa** | `4911 1111 1111 1113` | Apa saja | Masa depan |
| **Mastercard** | `5211 1111 1111 1117` | Apa saja | Masa depan |

> Untuk testing 3DS: gunakan `4811 1111 1111 1114` dan klik "Accept" saat diminta 3DS.
> Untuk simulasi gagal: gunakan kartu dengan saldo tidak mencukupi atau kartu kadaluarsa.

---

## ✨ Fitur Lengkap

### ✅ Website (Vue.js)
- [x] Landing page dengan hero & stats real-time
- [x] Banner management (CRUD banner landing page)
- [x] Registrasi customer/trainer dengan form lengkap (nama, email, password, provinsi, kota, role, spesialisasi)
- [x] Login dengan JWT
- [x] Verifikasi email via OTP (registrasi & auto-resend saat login)
- [x] Lupa password via OTP
- [x] Reset password (OTP + new password)
- [x] Dashboard member (statistik booking)
- [x] Cari Trainer dengan filter
- [x] Booking sesi latihan
- [x] Booking Saya (aktif & riwayat)
- [x] Pembayaran via Midtrans (redirect)
- [x] Profil & Edit Profil
- [x] Upload foto profil
- [x] Harga sesi (Pricing)
- [x] Progress latihan
- [x] Admin panel lengkap (CRUD Users, Trainer, Booking, Artikel, Promo, FAQ, Banner, Notifikasi)
- [x] Trainer panel (kelola sesi, lihat client)
- [x] Artikel fitness
- [x] FAQ
- [x] Promo/Voucher
- [x] Notifikasi sistem

### ✅ Mobile App (Flutter)
- [x] App icon GymBuddy (generate via flutter_launcher_icons)
- [x] Login & Register (customer only — trainer/admin ditolak)
- [x] Form registrasi dengan field Provinsi & Kota
- [x] Verifikasi email via OTP
- [x] Lupa password via OTP (flow sama dengan web)
- [x] Reset password (OTP + new password + confirm, dengan resend OTP & cooldown)
- [x] Home screen (sesi & booking)
- [x] Cari Trainer dengan foto
- [x] Booking Saya (dengan foto trainer)
- [x] Detail sesi (dengan foto trainer)
- [x] Pembayaran via Midtrans (inAppWebView)
- [x] Profil & Edit Profil
- [x] Upload foto profil (via kamera/gallery)
- [x] Progress latihan
- [x] Notifikasi
- [x] About screen
- [x] Pricing screen
- [x] Bottom navigation (Home, Cari, Booking)

### ✅ Backend API (Node.js + Express + Drizzle)
- [x] Auth: register (customer/trainer/admin), login, OTP verify, resend OTP, forgot password, reset password
- [x] JWT auth (7 hari) + bcrypt hash
- [x] OTP via email (Resend) — TTL 5 menit, max 5 attempts
- [x] Email normalisasi lowercase (case-insensitive auth)
- [x] Role-based access (admin/trainer/customer)
- [x] CRUD User & Profile
- [x] CRUD Session (trainer/admin)
- [x] CRUD Booking + status management
- [x] Midtrans payment integration + webhook
- [x] Upload foto profil (multer)
- [x] Reviews
- [x] Progress & Body Progress
- [x] Diet Programs
- [x] Reminders
- [x] Notifications (kirim & kelola)
- [x] Articles, FAQ, Promo, Banners (CRUD)
- [x] Analytics dashboard (admin)
- [x] Rate limiting (global + auth endpoint)
- [x] Helmet security headers
- [x] Compression
- [x] Structured logging (Pino)
- [x] Zod schema validation
- [x] Health check endpoint

---

## 📁 Struktur Project

```
gymbuddy-app/
├── backend/                          # Node.js Express API (TypeScript)
│   ├── server.js                     # Entry point (tsx)
│   ├── drizzle.config.ts             # Drizzle Kit config
│   ├── drizzle/                      # Generated migrations
│   ├── src/
│   │   ├── app.ts                    # Express app setup (CORS, helmet, rate-limit, routes)
│   │   ├── config/
│   │   │   └── env.ts                # Env validation (Zod) & DB config
│   │   ├── db/
│   │   │   ├── client.ts             # PostgreSQL pool (pg + Drizzle)
│   │   │   ├── seed.ts               # Seed data
│   │   │   └── schema/               # Drizzle schema (14 tabel)
│   │   │       ├── users.ts
│   │   │       ├── sessions.ts
│   │   │       ├── bookings.ts
│   │   │       ├── reviews.ts
│   │   │       ├── progress.ts
│   │   │       ├── bodyProgress.ts
│   │   │       ├── notifications.ts
│   │   │       ├── articles.ts
│   │   │       ├── promo.ts
│   │   │       ├── banners.ts
│   │   │       ├── faq.ts
│   │   │       ├── reminders.ts
│   │   │       ├── dietPrograms.ts
│   │   │       └── index.ts
│   │   ├── middleware/
│   │   │   ├── auth.ts               # JWT verification (Bearer token)
│   │   │   ├── role.ts               # Role-based access control
│   │   │   ├── validate.ts           # Zod schema validation
│   │   │   ├── upload.ts             # Multer file upload
│   │   │   └── error.ts              # Error & not-found handler
│   │   ├── modules/                  # 17 feature modules
│   │   │   ├── auth/                 # *.controller.ts, *.service.ts, *.repo.ts, *.routes.ts, *.schema.ts
│   │   │   ├── user/
│   │   │   ├── session/
│   │   │   ├── trainer/
│   │   │   ├── booking/
│   │   │   ├── payment/
│   │   │   ├── review/
│   │   │   ├── progress/
│   │   │   ├── notification/
│   │   │   ├── article/
│   │   │   ├── promo/
│   │   │   ├── banner/
│   │   │   ├── faq/
│   │   │   ├── reminder/
│   │   │   ├── diet/
│   │   │   ├── upload/
│   │   │   └── analytics/
│   │   ├── types/
│   │   └── utils/
│   │       ├── jwt.ts                # signToken / verifyToken
│   │       ├── response.ts           # success / paginated / error helper
│   │       ├── emailService.ts       # Resend email (OTP & reset password)
│   │       ├── cache.ts              # NodeCache instance
│   │       └── logger.ts             # Pino logger
│   ├── uploads/profiles/             # Foto profil (local storage)
│   ├── .env                          # Environment variables (JANGAN commit!)
│   └── .env.example                  # Template env
│
├── frontend/                         # Vue 3 Web App
│   ├── src/
│   │   ├── App.vue
│   │   ├── main.js                   # Entry point (Pinia, Router)
│   │   ├── views/                    # Halaman-halaman
│   │   │   ├── home.vue              # Landing page
│   │   │   ├── about.vue
│   │   │   ├── trainer.vue
│   │   │   ├── LoginView.vue
│   │   │   ├── register.vue          # Form: nama, email, password, provinsi, kota, role, spesialisasi
│   │   │   ├── ForgotPassword.vue
│   │   │   ├── ResetPassword.vue     # OTP + new password
│   │   │   ├── VerifyOtp.vue
│   │   │   ├── dashboard/            # Dashboard member
│   │   │   │   ├── DashboardView.vue
│   │   │   │   ├── FindTrainers.vue
│   │   │   │   ├── MyBookings.vue
│   │   │   │   ├── PricingView.vue
│   │   │   │   ├── Progres.vue
│   │   │   │   ├── profile.vue
│   │   │   │   ├── EditProfileView.vue
│   │   │   │   └── SettingsView.vue
│   │   │   ├── dashboard_trainer/    # Dashboard trainer
│   │   │   │   ├── TrainerDashboard.vue
│   │   │   │   ├── ManageSessionsView.vue
│   │   │   │   ├── TrainerClientsView.vue
│   │   │   │   └── TrainerEditProfile.vue
│   │   │   └── admin/                # Panel admin
│   │   │       ├── AdminDashboard.vue
│   │   │       ├── AdminUsers.vue
│   │   │       ├── AdminTrainers.vue
│   │   │       ├── AdminBookings.vue
│   │   │       ├── AdminArticles.vue
│   │   │       ├── AdminPromo.vue
│   │   │       ├── AdminFaq.vue
│   │   │       ├── AdminBanners.vue
│   │   │       └── AdminNotifications.vue
│   │   ├── components/               # Navbar, Sidebar, Footer
│   │   ├── stores/
│   │   │   └── authStore.js          # Pinia auth store (user, token, init)
│   │   ├── utils/
│   │   │   └── api.js                # Axios instance (interceptor token + 401)
│   │   └── router/
│   │       └── index.js              # Vue Router + navigation guard
│   ├── .env                          # VITE_API_URL
│   ├── wrangler.jsonc                # Cloudflare Pages config
│   ├── tailwind.config.js
│   └── vite.config.js
│
├── mobile/                           # Flutter App
│   ├── lib/
│   │   ├── main.dart                 # Entry point (ProviderScope + router)
│   │   ├── routing/
│   │   │   └── app_router.dart       # GoRouter + redirect guard (auth check)
│   │   ├── services/
│   │   │   ├── api_service.dart      # Dio singleton (interceptor, all API calls)
│   │   │   ├── auth_provider.dart    # Riverpod AuthNotifier (login, register, logout)
│   │   │   └── ui_helpers.dart
│   │   └── screens/
│   │       ├── auth/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart       # Form: nama, email, password, confirm, provinsi, kota
│   │       │   ├── verify_otp_screen.dart
│   │       │   ├── forgot_password_screen.dart
│   │       │   └── reset_password_screen.dart # OTP + new password + confirm + resend
│   │       ├── home/home_screen.dart
│   │       ├── booking/
│   │       │   ├── find_trainers_screen.dart
│   │       │   └── my_bookings_screen.dart
│   │       ├── session/session_detail_screen.dart
│   │       ├── payment/
│   │       │   ├── payment_screen.dart
│   │       │   └── midtrans_webview_screen.dart
│   │       ├── profile/
│   │       │   ├── profile_screen.dart
│   │       │   └── edit_profile_screen.dart
│   │       ├── progress/progress_screen.dart
│   │       ├── notifications/notifications_screen.dart
│   │       ├── pricing/pricing_screen.dart
│   │       ├── about/about_screen.dart
│   │       ├── admin/                # Admin panel (8 screens)
│   │       └── trainer/              # Trainer panel (3 screens)
│   ├── assets/images/
│   │   ├── logo.png                  # Logo di dalam app
│   │   └── app_logo.png              # Source untuk flutter_launcher_icons
│   ├── android/                      # Android config (icon sudah di-generate)
│   ├── ios/                          # iOS config (icon sudah di-generate)
│   ├── pubspec.yaml                  # Dependencies + flutter_launcher_icons config
│   └── test/
│
├── .gitignore
└── TUTOR.md                          # Dokumentasi ini
```

---

## 🔌 API Endpoints

Base URL: `https://api.gymbuddy.site/api/v1` (production) atau `http://localhost:5000/api/v1` (development)

### Auth
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| POST | `/auth/register` | Registrasi customer baru + kirim OTP | — |
| POST | `/auth/register/trainer` | Registrasi trainer baru + kirim OTP | — |
| POST | `/auth/register/admin` | Registrasi admin baru | admin |
| POST | `/auth/login` | Login (cek verifikasi email) | — |
| POST | `/auth/verify-otp` | Verifikasi OTP registrasi | — |
| POST | `/auth/resend-otp` | Kirim ulang OTP registrasi | — |
| POST | `/auth/forgot-password` | Kirim OTP reset password | — |
| POST | `/auth/reset-password` | Reset password dengan OTP | — |
| GET | `/auth/me` | Get data user login | token |

### User
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/users` | List semua user | admin |
| GET | `/users/profile` | Get profil user login | token |
| PUT | `/users/profile` | Update profil sendiri | token |
| GET | `/users/email/:email` | Cari user by email | admin |
| GET | `/users/:id` | Get user by ID | token |
| PUT | `/users/:id` | Update user by ID | owner/admin |
| DELETE | `/users/:id` | Hapus user | admin |

### Session
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/sessions` | List sesi (pagination, search, filter kota) | — |
| GET | `/sessions/upcoming` | Sesi mendatang | — |
| GET | `/sessions/:id` | Detail sesi | — |
| POST | `/sessions` | Buat sesi | trainer/admin |
| PUT | `/sessions/:id` | Update sesi | trainer/admin |
| DELETE | `/sessions/:id` | Hapus sesi | trainer/admin |

### Trainer
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/trainers` | List trainer (search, filter) | — |
| GET | `/trainers/:id` | Detail trainer | — |
| GET | `/trainers/:id/sessions` | Sesi milik trainer | — |
| PUT | `/trainers/:id` | Update profil trainer | owner/admin |

### Booking
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/bookings` | List semua booking | admin |
| GET | `/bookings/my` | Booking saya | token |
| GET | `/bookings/:id` | Detail booking | token |
| POST | `/bookings` | Buat booking baru | customer/admin |
| PATCH | `/bookings/:id/status` | Update status booking | customer/trainer/admin |
| DELETE | `/bookings/my` | Reset booking saya | customer/admin |
| DELETE | `/bookings/all` | Reset semua booking | admin |

### Payment
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| POST | `/payments/create` | Buat transaksi Midtrans | token |
| POST | `/payments/notification` | Webhook dari Midtrans | — |
| GET | `/payments/config` | Client key Midtrans | token |
| GET | `/payments/:booking_id/status` | Cek status pembayaran | token |

### Review
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/reviews` | List review | — |
| POST | `/reviews` | Buat review | customer/admin |
| PUT | `/reviews/:id` | Update review | token |
| DELETE | `/reviews/:id` | Hapus review | token |

### Progress
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/progress` | Progress latihan saya | token |
| POST | `/progress` | Catat progress | token |
| PUT | `/progress/:id` | Update progress | token |
| DELETE | `/progress/:id` | Hapus progress | token |
| GET | `/progress/body` | Body progress saya | token |
| POST | `/progress/body` | Catat body progress | token |
| PUT | `/progress/body/:id` | Update body progress | token |
| DELETE | `/progress/body/:id` | Hapus body progress | token |

### Diet Program
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/diet-programs` | Diet program saya | token |
| POST | `/diet-programs` | Buat diet program | token |
| PUT | `/diet-programs/:id` | Update diet program | token |
| DELETE | `/diet-programs/:id` | Hapus diet program | token |

### Reminder
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/reminders` | Reminder saya | token |
| POST | `/reminders` | Buat reminder | token |
| PUT | `/reminders/:id` | Update reminder | token |
| DELETE | `/reminders/:id` | Hapus reminder | token |

### Notification
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/notifications` | Notifikasi saya (pagination) | token |
| GET | `/notifications/unread-count` | Jumlah belum dibaca | token |
| PATCH | `/notifications/read-all` | Tandai semua dibaca | token |
| PATCH | `/notifications/:id/read` | Tandai satu dibaca | token |
| DELETE | `/notifications/:id` | Hapus notifikasi | token |

### Article
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/articles` | List artikel | — |
| GET | `/articles/slug/:slug` | Artikel by slug | — |
| GET | `/articles/:id` | Artikel by ID | — |
| POST | `/articles` | Buat artikel | admin/trainer |
| PUT | `/articles/:id` | Update artikel | admin/trainer |
| DELETE | `/articles/:id` | Hapus artikel | admin |

### Promo
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/promos` | List promo | — |
| GET | `/promos/active` | Promo aktif | — |
| GET | `/promos/code/:kode` | Cek promo by kode | — |
| GET | `/promos/:id` | Detail promo | — |
| POST | `/promos` | Buat promo | admin |
| PUT | `/promos/:id` | Update promo | admin |
| DELETE | `/promos/:id` | Hapus promo | admin |

### Banner
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/banners` | List banner | — |
| GET | `/banners/active` | Banner aktif | — |
| GET | `/banners/:id` | Detail banner | — |
| POST | `/banners` | Buat banner | admin |
| PUT | `/banners/:id` | Update banner | admin |
| DELETE | `/banners/:id` | Hapus banner | admin |

### FAQ
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/faqs` | List FAQ | — |
| GET | `/faqs/active` | FAQ aktif | — |
| GET | `/faqs/:id` | Detail FAQ | — |
| POST | `/faqs` | Buat FAQ | admin |
| PUT | `/faqs/:id` | Update FAQ | admin |
| DELETE | `/faqs/:id` | Hapus FAQ | admin |

### Upload
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| POST | `/upload/profile` | Upload foto profil (multipart, field: `foto`) | token |

### Analytics
| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/analytics/dashboard` | Statistik dashboard (total users, sessions, bookings, revenue) | admin |

### Health
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/health` | Health check (status + timestamp) |

---

## 🔐 Environment Variables

### Backend (`backend/.env`)

Salin dari `backend/.env.example` dan sesuaikan:

```env
# ===== DATABASE (PostgreSQL) =====
# Option 1: Connection URL (recommended untuk Neon/Railway/Render)
DATABASE_URL=postgresql://user:password@host/database?sslmode=require

# Option 2: Individual credentials (untuk local DB)
# DB_HOST=localhost
# DB_PORT=5432
# DB_USER=postgres
# DB_PASSWORD=
# DB_NAME=gymbuddy
# DB_SSL=true              # Set true jika DB butuh SSL (Neon, Aiven, Railway)

# ===== JWT =====
JWT_SECRET=your-secret-key-change-in-production

# ===== SERVER =====
PORT=5000
NODE_ENV=production        # development | production | test

# ===== CORS =====
FRONTEND_URL=https://gymbuddy.site

# ===== EMAIL (Resend) =====
# Untuk OTP verifikasi & reset password
RESEND_API_KEY=re_your_api_key
EMAIL_FROM=GymBuddy <noreply@notif.gymbuddy.site>

# ===== MIDTRANS (Payment) =====
# Sandbox (development):
MIDTRANS_SERVER_KEY=SB-Mid-server-your-key
MIDTRANS_CLIENT_KEY=SB-Mid-client-your-key
MIDTRANS_IS_PRODUCTION=false

# Production:
# MIDTRANS_SERVER_KEY=Mid-server-your-key
# MIDTRANS_CLIENT_KEY=Mid-client-your-key
# MIDTRANS_IS_PRODUCTION=true
```

| Variable | Wajib | Default | Deskripsi |
|----------|-------|---------|-----------|
| `DATABASE_URL` | ya* | — | Connection string PostgreSQL |
| `DB_HOST` | ya** | localhost | Host DB (jika tidak pakai DATABASE_URL) |
| `DB_PORT` | no | 5432 | Port DB |
| `DB_USER` | no | postgres | User DB |
| `DB_PASSWORD` | no | (kosong) | Password DB |
| `DB_NAME` | no | gymbuddy | Nama database |
| `DB_SSL` | no | — | `true` untuk aktifkan SSL |
| `JWT_SECRET` | **ya** | — | Secret key JWT (wajib diisi) |
| `PORT` | no | 5000 | Port server |
| `NODE_ENV` | no | production | Environment mode |
| `FRONTEND_URL` | no | http://localhost:5173 | URL frontend untuk CORS |
| `RESEND_API_KEY` | no | (kosong) | API key Resend untuk email |
| `EMAIL_FROM` | no | GymBuddy \<noreply@gymbuddy.site\> | Email pengirim |
| `MIDTRANS_SERVER_KEY` | no | (kosong) | Server key Midtrans |
| `MIDTRANS_CLIENT_KEY` | no | (kosong) | Client key Midtrans |
| `MIDTRANS_IS_PRODUCTION` | no | false | `true` untuk Midtrans production |

> *Pilih salah satu: `DATABASE_URL` ATAU individual credentials (`DB_HOST` dll).
> Jika `RESEND_API_KEY` kosong, OTP tidak akan terkirim (error di log).

### Frontend (`frontend/.env`)

```env
# API URL backend
VITE_API_URL=http://localhost:5000/api/v1
```

| Variable | Wajib | Default | Deskripsi |
|----------|-------|---------|-----------|
| `VITE_API_URL` | no | auto-detect | URL backend API. Jika kosong: localhost → `http://localhost:5000/api/v1`, lainnya → `https://api.gymbuddy.site/api/v1` |

### Mobile (`mobile/lib/services/api_service.dart`)

Tidak pakai `.env`, konfigurasi hardcoded di `api_service.dart`:

```dart
static const String _prodUrl = 'https://api.gymbuddy.site/api/v1';
static const String _devUrl = 'http://10.0.2.2:5000/api/v1';
static const bool _isProduction = true;
```

> `10.0.2.2` = alias ke `localhost` dari Android emulator.
> Untuk device real development, ganti `_devUrl` ke IP lokal komputer (mis. `http://192.168.1.5:5000/api/v1`).

---

## 🚢 Deployment

### Backend (Railway / Render)

Backend pakai TypeScript yang dijalankan dengan `tsx`. Tidak perlu build step — Railway/Render jalankan langsung via `npm start`.

```bash
cd backend
# Set environment variables di dashboard Railway/Render:
# - DATABASE_URL, JWT_SECRET, FRONTEND_URL, RESEND_API_KEY, EMAIL_FROM
# - MIDTRANS_SERVER_KEY, MIDTRANS_CLIENT_KEY, MIDTRANS_IS_PRODUCTION
# - NODE_ENV=production

# Start command: npm start
# Atau set di Procfile/package.json scripts
```

Domain production: `https://api.gymbuddy.site`

### Frontend (Cloudflare Pages)

Frontend di-deploy ke Cloudflare Pages. Config ada di `frontend/wrangler.jsonc`:

```jsonc
{
  "name": "gymbuddy-app",
  "pages_build_output_dir": "dist",
  "compatibility_date": "2025-06-23"
}
```

```bash
cd frontend
npm run build                    # Output: dist/
npx wrangler pages deploy dist   # Deploy ke Cloudflare Pages
```

Set environment variable di dashboard Cloudflare Pages:
- `VITE_API_URL` = `https://api.gymbuddy.site/api/v1`

Domain production: `https://gymbuddy.site`

### Database (Neon)

Database PostgreSQL di Neon (serverless PostgreSQL). Connection string format:
```
postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require
```

Migrasi schema:
```bash
cd backend
npm run db:generate    # Generate migration dari perubahan schema
npm run db:migrate     # Apply migration ke database
npm run db:studio      # Buka Drizzle Studio (GUI untuk lihat/edit data)
```

---

## 📱 Build Mobile (APK / IPA)

### Prasyarat
- Flutter SDK 3.x terinstall
- Android SDK (untuk APK)
- Xcode + CocoaPods (untuk IPA, macOS only)

### Generate App Icon (jika logo berubah)

Logo source: `mobile/assets/images/app_logo.png` (rekomendasi 1024x1024 PNG)

```bash
cd mobile
dart run flutter_launcher_icons
```

Icon akan di-generate ke:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` (5 density)
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (24 ukuran)

### Build APK (Android)

```bash
cd mobile

# Build APK release (single APK untuk semua ABI)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

Atau pecah per-ABI (APK lebih kecil per device):

```bash
flutter build apk --split-per-abi --release

# Output:
# - app-armeabi-v7a-release.apk    (32-bit ARM — lama)
# - app-arm64-v8a-release.apk      (64-bit ARM — kebanyakan device modern)
# - app-x86_64-release.apk         (emulator)
```

### Build App Bundle (untuk Google Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build IPA (iOS, butuh macOS + Xcode)

```bash
cd mobile
flutter build ios --release
# Lalu buka Xcode: open ios/Runner.xcworkspace → Archive → Distribute
```

### Run di Device/Emulator

```bash
# List device tersedia
flutter devices

# Run di Android emulator
flutter run -d emulator-5554

# Run di device real (aktifkan USB debugging)
flutter run -d <device-id>

# Run di iOS simulator (macOS only)
flutter run -d simulator
```

---

## 📊 Status Testing

| Test | Status | Detail |
|------|--------|--------|
| **Flutter Analyze** | ✅ | Clean (hanya info `avoid_print` dari debug logging) |
| **Flutter Run (Emulator)** | ✅ | Build & launch sukses di Android 17 emulator |
| **Mobile Auth Flow** | ✅ | Login, Register (dengan provinsi/kota), OTP, Forgot/Reset Password — semua berfungsi |
| **Frontend Build** | ✅ | Vite build success |
| **Backend APIs** | ✅ | All endpoints responding |
| **Backend Production** | ✅ | Deployed di `api.gymbuddy.site` |
| **Frontend Production** | ✅ | Deployed di `gymbuddy.site` |
| **Database** | ✅ | PostgreSQL Neon connected |

---

## 🐛 Known Issues & Catatan

1. **Mobile khusus customer** — Trainer & admin tidak bisa login di mobile app (ditolak dengan pesan "Akun trainer/admin tidak dapat digunakan di aplikasi mobile"). Gunakan website untuk trainer/admin.

2. **Registrasi mobile vs web** — Mobile hanya bisa daftar sebagai customer (dengan field: nama, email, password, confirm password, provinsi, kota). Web bisa daftar sebagai customer atau trainer (dengan field tambahan: role selector & spesialisasi untuk trainer).

3. **OTP disimpan in-memory** — OTP disimpan di `NodeCache` (RAM server backend), bukan database. Jika server restart, OTP yang belum diverifikasi akan hilang dan harus minta kirim ulang.

4. **Akun test harus `is_verified=true`** — Jika akun test belum diverifikasi, login akan ditolak dengan `EMAIL_NOT_VERIFIED` dan OTP baru dikirim otomatis ke email.

5. **Email case-insensitive** — Semua email dinormalisasi ke lowercase di backend (register, login, forgot password, reset password). `User@Gmail.com` dan `user@gmail.com` dianggap sama.

6. **Admin register tanpa OTP** — Registrasi admin (via endpoint `/auth/register/admin`) langsung return token tanpa verifikasi email, berbeda dengan customer/trainer yang butuh OTP.

7. **File upload local storage** — Foto profil disimpan di `backend/uploads/profiles/`. Tidak pakai cloud storage (S3/R2). Jika backend di-deploy ulang dengan volume baru, foto lama hilang.

---

> **Dibuat oleh:** Arif Rachman
> **Email:** 2311102300@ittelkom-pwt.ac.id
> **Versi:** 2.0.0
> **Dokumen ini:** TUTOR.md — Panduan Lengkap GymBuddy
