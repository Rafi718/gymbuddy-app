# PRD — GymBuddy Backend Redesign v2.0

> **Status:** Draft
> **Tanggal:** 23 Juni 2026
> **Author:** Pair Programming Session

---

## 1. Latar Belakang & Masalah

### 1.1 Kondisi Saat Ini

Backend GymBuddy saat ini memiliki masalah fundamental:

- **Raw SQL queries** tersebar di 15+ controller files — tidak ada schema type safety, mudah typo, sulit di-maintain
- **Database driver inconsistency** — codebase campuran `mariadb` dan `mysql2` pattern, beberapa controller mengasumsikan format return berbeda
- **Bug latent** — column name mismatch (`jam_nyatat` vs `recorded_at`), destructuring bug di `session.controller.js`, error code MySQL hard-coded (`ER_DUP_ENTRY`)
- **Tidak ada migration system** — schema di-manage via manual SQL dump (`localhost.sql`), tidak ada versioning
- **Tidak ada validation layer** — input validation dilakukan manual dan inconsistent antar controller
- **Error handling inconsistent** — beberapa controller pakai `success/error` helper, beberapa pakai `res.status().json()` langsung
- **Cache strategy fragile** — `node-cache` in-memory, keys di-hard-code string literal, mudah miss/invalidate salah
- **N+1 queries** — beberapa endpoint melakukan query berulang dalam loop (e.g., `enrichTrainerPhoto` di `trainer.controller.js`)
- **Role middleware terbatas** — hanya cek string role, tidak ada policy-based authorization
- **Upload file coupling** — multer storage hard-coded ke local filesystem, tidak ada abstraction untuk cloud storage

### 1.2 Mengapa Redesign (Bukan Patch)

Patching layer demi layer akan menghasilkan codebase hybrid yang semakin sulit dipahami. Redesign total backend dengan:

- **ORM (Drizzle)** untuk type safety, migration system, dan query builder
- **Layered architecture** untuk separation of concerns
- **Consistent patterns** untuk validation, error handling, dan response format

Frontend (Vue) dan mobile (Flutter) akan menyesuaikan kontrak API baru.

---

## 2. Tujuan & Scope

### 2.1 Tujuan

1. **Type-safe database layer** — schema, query, dan return type semua typed via Drizzle ORM
2. **Migration system** — schema changes versioned dan reversible via `drizzle-kit`
3. **Consistent API contract** — uniform response format, error codes, pagination, dan filtering
4. **Proper validation** — request body/params/query validated via Zod schema
5. **Clean architecture** — Route → Controller → Service → Repository, setiap layer punya responsibility tunggal
6. **Testable** — setiap service layer dapat di-unit-test tanpa database real
7. **Production-ready** — proper error handling, logging, health check, dan graceful shutdown

### 2.2 In Scope

- Backend Node.js + Express + Drizzle ORM + PostgreSQL
- Database schema redesign (normalisasi, naming convention, constraints)
- API endpoint redesign (RESTful, consistent naming, pagination, filtering)
- Auth & authorization system (JWT + role-based access control)
- Midtrans payment integration
- File upload abstraction (local + cloud-ready)
- Notification system
- Analytics/dashboard endpoints
- Migration scripts dari schema lama ke baru

### 2.3 Out of Scope

- Frontend Vue refactor (phase berikutnya, menyesuaikan API baru)
- Mobile Flutter refactor (phase berikutnya)
- Real-time WebSocket (not needed untuk MVP baru)
- Microservices split (overkill untuk skala ini)

---

## 3. Tech Stack

| Layer | Teknologi | Alasan |
|-------|-----------|--------|
| **Runtime** | Node.js 20+ | Existing, LTS |
| **Framework** | Express 5.x | Existing, cukup untuk kebutuhan |
| **ORM** | Drizzle ORM | Type-safe, lightweight, SQL-first, migration built-in |
| **Database** | PostgreSQL 15+ | Sudah dipilih di fase sebelumnya, robust, open-source |
| **Validation** | Zod | TypeScript-first, integrasi natural dengan Drizzle |
| **Auth** | JWT (jsonwebtoken) | Existing, cukup untuk RBAC |
| **Payment** | Midtrans Snap | Existing, tidak berubah |
| **Upload** | Multer + abstraction layer | Local storage sekarang, cloud-ready untuk masa depan |
| **Cache** | node-cache | Masih cukup untuk skala saat ini |
| **Logging** | Pino | Structured logging, performa tinggi |
| **Security** | helmet, cors, express-rate-limit | Existing, tetap dipakai |

### Package Dependencies (Baru)

```
drizzle-orm        — ORM
drizzle-kit        — Migration CLI
zod                — Schema validation
pino               — Structured logging
pino-http          — HTTP request logging
```

### Package Dependencies (Dihapus)

```
mariadb            — diganti drizzle-orm + pg
mysql2             — sudah tidak dipakai
mongoose           — tidak pernah dipakai
sequelize          — tidak pernah dipakai
express-mysql-session — tidak dipakai
express-session    — tidak dipakai
pg                 — tetap dipakai, tapi via drizzle (drizzle-orm/pg-driver)
```

---

## 4. Arsitektur Backend

### 4.1 Struktur Folder

```
backend/
├── src/
│   ├── db/
│   │   ├── schema/           — Drizzle schema definitions
│   │   │   ├── users.ts
│   │   │   ├── sessions.ts
│   │   │   ├── bookings.ts
│   │   │   ├── reviews.ts
│   │   │   ├── progress.ts
│   │   │   ├── bodyProgress.ts
│   │   │   ├── notifications.ts
│   │   │   ├── articles.ts
│   │   │   ├── promo.ts
│   │   │   ├── banners.ts
│   │   │   ├── faq.ts
│   │   │   ├── reminders.ts
│   │   │   ├── dietPrograms.ts
│   │   │   └── index.ts      — re-export semua schema
│   │   ├── client.ts         — Drizzle client setup (Pool + drizzle())
│   │   └── seed.ts           — Seed data script
│   │
│   ├── modules/              — Feature modules (domain-driven)
│   │   ├── auth/
│   │   │   ├── auth.routes.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.schema.ts    — Zod validation schemas
│   │   │   └── auth.repo.ts      — Drizzle queries
│   │   ├── user/
│   │   ├── session/
│   │   ├── booking/
│   │   ├── payment/
│   │   ├── review/
│   │   ├── progress/
│   │   ├── analytics/
│   │   ├── article/
│   │   ├── promo/
│   │   ├── banner/
│   │   ├── faq/
│   │   ├── notification/
│   │   ├── trainer/
│   │   └── upload/
│   │
│   ├── middleware/
│   │   ├── auth.ts           — JWT verification
│   │   ├── role.ts           — RBAC (admin, trainer, customer)
│   │   ├── error.ts          — Global error handler
│   │   ├── notFound.ts       — 404 handler
│   │   └── upload.ts         — Multer config
│   │
│   ├── utils/
│   │   ├── response.ts       — Unified response helper
│   │   ├── jwt.ts            — JWT sign/verify
│   │   ├── cache.ts          — Cache helper
│   │   └── logger.ts         — Pino logger
│   │
│   ├── config/
│   │   └── env.ts            — Centralized env config (Zod-validated)
│   │
│   └── app.ts                — Express app setup (middleware, routes)
│
├── drizzle/                  — Migration files (generated)
├── drizzle.config.ts         — Drizzle Kit config
├── server.js                 — Entry point
├── package.json
└── .env.example
```

### 4.2 Layer Architecture

```
HTTP Request
    │
    ▼
┌──────────┐     ┌──────────────┐     ┌───────────────┐     ┌──────────┐
│  Route    │────▶│  Controller  │────▶│   Service     │────▶│  Repo    │
│  (path,   │     │  (req/res,   │     │  (business    │     │ (Drizzle │
│   method) │     │   validate)  │     │   logic)      │     │  queries)│
└──────────┘     └──────────────┘     └───────────────┘     └──────────┘
                                            │                      │
                                            ▼                      ▼
                                     ┌──────────┐          ┌──────────┐
                                     │  Cache   │          │PostgreSQL│
                                     └──────────┘          └──────────┘
```

- **Route** — definisi path + method + middleware chain
- **Controller** — parse HTTP request, validate via Zod, call service, format response
- **Service** — business logic, orchestration antar repo, cache, external API calls
- **Repo** — Drizzle ORM queries, murni database access

### 4.3 Response Format (Unified)

Semua endpoint mengembalikan format yang konsisten:

```json
// Success
{
  "success": true,
  "data": { ... },          // object atau array
  "message": "...",         // optional
  "meta": {                 // optional, untuk pagination
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",   // machine-readable error code
    "message": "...",              // human-readable message
    "details": [ ... ]             // optional, untuk validation errors
  }
}
```

### 4.4 Error Codes

| Code | HTTP Status | Deskripsi |
|------|-------------|-----------|
| `VALIDATION_ERROR` | 400 | Input tidak valid |
| `UNAUTHORIZED` | 401 | Token tidak ada atau tidak valid |
| `FORBIDDEN` | 403 | Tidak punya akses ke resource |
| `NOT_FOUND` | 404 | Resource tidak ditemukan |
| `CONFLICT` | 409 | Duplikat / conflict (e.g., email sudah terdaftar) |
| `PAYMENT_REQUIRED` | 402 | Pembayaran diperlukan |
| `RATE_LIMITED` | 429 | Terlalu banyak request |
| `INTERNAL_ERROR` | 500 | Server error |

---

## 5. Database Schema (Redesign)

### 5.1 Naming Convention

- **Snake_case** untuk tabel dan kolom (PostgreSQL convention)
- **Plural** untuk nama tabel (`users`, `sessions`, `bookings`)
- **Foreign key**: `{table_singular}_id` (e.g., `trainer_id`, `session_id`)
- **Timestamps**: `created_at`, `updated_at` (semua tabel)
- **Boolean**: gunakan `boolean` (bukan `smallint`/`tinyint`)
- **Enum**: gunakan PostgreSQL `enum` type atau `varchar` dengan `CHECK` constraint

### 5.2 Tabel

#### `users`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | Auto-increment |
| nama | varchar(100) | NOT NULL | Nama lengkap |
| email | varchar(255) | NOT NULL, UNIQUE | Email |
| password | varchar(255) | NOT NULL | Bcrypt hash |
| role | enum | NOT NULL, DEFAULT 'customer' | `customer`, `trainer`, `admin` |
| jenis_kelamin | char(1) | nullable, CHECK | `L`, `P` |
| no_telp | varchar(20) | nullable | Nomor telepon |
| tanggal_lahir | date | nullable | Tanggal lahir |
| foto | varchar(255) | nullable | Path/URL foto profil |
| bio | text | nullable | Bio (khusus trainer) |
| propinsi | varchar(45) | DEFAULT '' | Provinsi |
| kota | varchar(45) | DEFAULT '' | Kota |
| spesialisasi | varchar(100) | nullable | Spesialisasi trainer |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | Auto-update via trigger |

#### `sessions`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| title | varchar(100) | NOT NULL | Judul sesi |
| description | text | nullable | Deskripsi (rename dari `deskripsi`) |
| trainer_id | integer | NOT NULL, FK → users.id | |
| start_time | timestamptz | NOT NULL | |
| end_time | timestamptz | nullable | |
| price | numeric(10,2) | DEFAULT 0 | Harga |
| status | enum | NOT NULL, DEFAULT 'scheduled' | `scheduled`, `ongoing`, `completed`, `cancelled` |
| max_participants | integer | DEFAULT 1 | |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | |

#### `bookings`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| session_id | integer | NOT NULL, FK → sessions.id | |
| member_id | integer | NOT NULL, FK → users.id | |
| status | enum | NOT NULL, DEFAULT 'pending' | `pending`, `confirmed`, `completed`, `cancelled` |
| payment_status | enum | DEFAULT 'pending' | `pending`, `settlement`, `cancel`, `expire` |
| payment_method | varchar(50) | nullable | |
| payment_amount | numeric(10,2) | DEFAULT 0 | |
| payment_date | timestamptz | nullable | |
| midtrans_transaction_id | varchar(100) | nullable | |
| midtrans_order_id | varchar(100) | nullable | |
| midtrans_token | text | nullable | |
| catatan | text | nullable | |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | |
| | | UNIQUE (session_id, member_id) | Cegah double booking |

#### `reviews`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| session_id | integer | NOT NULL, FK → sessions.id | |
| member_id | integer | NOT NULL, FK → users.id | |
| rating_score | smallint | NOT NULL, CHECK (1-5) | |
| comment | text | nullable | |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | |

#### `progress`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| member_id | integer | NOT NULL, FK → users.id | |
| booking_id | integer | nullable, FK → bookings.id | |
| activity | varchar(100) | NOT NULL | |
| duration | integer | NOT NULL | Durasi dalam menit |
| note | text | nullable | |
| recorded_at | timestamptz | DEFAULT now() | |

#### `body_progress`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| member_id | integer | NOT NULL, FK → users.id | |
| berat_badan | numeric(5,2) | nullable | Berat (kg) |
| tinggi_badan | numeric(5,2) | nullable | Tinggi (cm) |
| bmi | numeric(4,2) | nullable | Auto-calculate |
| body_fat | numeric(4,1) | nullable | Body fat % |
| target_berat | numeric(5,2) | nullable | Target berat |
| foto_before | varchar(255) | nullable | |
| foto_after | varchar(255) | nullable | |
| catatan | text | nullable | |
| recorded_at | timestamptz | DEFAULT now() | |

#### `notifications`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| user_id | integer | NOT NULL, FK → users.id | |
| title | varchar(200) | NOT NULL | |
| message | text | NOT NULL | |
| type | enum | DEFAULT 'system' | `booking`, `payment`, `progress`, `promo`, `system` |
| is_read | boolean | DEFAULT false | |
| created_at | timestamptz | DEFAULT now() | |

#### `articles`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| title | varchar(200) | NOT NULL | |
| slug | varchar(200) | NOT NULL, UNIQUE | |
| content | text | nullable | |
| excerpt | text | nullable | |
| kategori | enum | DEFAULT 'Workout' | `Diet`, `Bulking`, `Cutting`, `Workout`, `Motivasi` |
| author_id | integer | nullable, FK → users.id | |
| foto | varchar(255) | nullable | |
| is_published | boolean | DEFAULT false | |
| published_at | timestamptz | nullable | |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | |

#### `promo`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| kode | varchar(50) | NOT NULL, UNIQUE | |
| judul | varchar(200) | NOT NULL | |
| deskripsi | text | nullable | |
| tipe | enum | DEFAULT 'nominal' | `persen`, `nominal` |
| nilai | numeric(10,2) | NOT NULL | |
| min_booking | integer | DEFAULT 1 | |
| maks_diskon | numeric(10,2) | nullable | |
| kuota | integer | nullable | |
| terpakai | integer | DEFAULT 0 | |
| tanggal_mulai | timestamptz | nullable | |
| tanggal_selesai | timestamptz | nullable | |
| is_active | boolean | DEFAULT true | |
| created_at | timestamptz | DEFAULT now() | |

#### `banners`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| judul | varchar(200) | nullable | |
| deskripsi | text | nullable | |
| gambar | varchar(255) | NOT NULL | |
| link | varchar(255) | nullable | |
| urutan | integer | DEFAULT 0 | |
| is_active | boolean | DEFAULT true | |
| created_at | timestamptz | DEFAULT now() | |

#### `faq`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| pertanyaan | text | NOT NULL | |
| jawaban | text | NOT NULL | |
| kategori | varchar(50) | DEFAULT 'umum' | |
| urutan | integer | DEFAULT 0 | |
| is_active | boolean | DEFAULT true | |
| created_at | timestamptz | DEFAULT now() | |

#### `reminders`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| user_id | integer | NOT NULL, FK → users.id | |
| judul | varchar(200) | NOT NULL | |
| tipe | enum | DEFAULT 'latihan' | `latihan`, `minum`, `makan`, `tidur`, `custom` |
| waktu | time | nullable | |
| hari | varchar(50) | nullable | |
| is_active | boolean | DEFAULT true | |
| created_at | timestamptz | DEFAULT now() | |

#### `diet_programs`
| Kolom | Tipe | Constraints | Deskripsi |
|-------|------|-------------|-----------|
| id | serial | PK | |
| user_id | integer | NOT NULL, FK → users.id | |
| tipe | enum | NOT NULL | `bulking`, `cutting`, `maintenance` |
| target_kalori | integer | nullable | |
| target_protein | integer | nullable | |
| target_karbohidrat | integer | nullable | |
| target_lemak | integer | nullable | |
| tanggal_mulai | date | nullable | |
| tanggal_selesai | date | nullable | |
| is_active | boolean | DEFAULT true | |
| catatan | text | nullable | |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | nullable | |

### 5.3 Perubahan Schema dari Versi Lama

| Aspek | Lama | Baru | Alasan |
|-------|------|------|--------|
| Nama tabel | `user` (reserved keyword) | `users` | Convention + hindari quoting |
| Nama kolom | `deskripsi` (mix bahasa) | `description` di sessions | Konsistensi bahasa Inggris |
| Boolean | `smallint` (0/1) | `boolean` (true/false) | Type-safe, PostgreSQL native |
| Enum | `varchar` + CHECK | PostgreSQL `enum` type | Lebih restrictive, readable |
| Timestamp | `TIMESTAMP` (no tz) | `timestamptz` | Best practice, hindari ambiguity |
| `updated_at` | `ON UPDATE current_timestamp()` | Trigger function | PostgreSQL tidak punya native ON UPDATE |
| Booking status | `Pending`, `Confirmed`, `Completed`, `Cancel` (PascalCase) | `pending`, `confirmed`, `completed`, `cancelled` (lowercase) | Convention |

---

## 6. API Endpoints (Redesign)

### 6.1 Konvensi

- **RESTful** — resource-based naming, HTTP verbs sesuai operasi
- **Plural nouns** — `/api/users`, `/api/sessions`, `/api/bookings`
- **Pagination** — `?page=1&limit=20` → response menyertakan `meta` object
- **Filtering** — `?search=...&status=...&kategori=...`
- **Sorting** — `?sort=created_at&order=desc`
- **Versioning** — prefix `/api/v1/` (siap untuk future breaking changes)

### 6.2 Auth

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/v1/auth/register` | Public | Registrasi customer |
| POST | `/api/v1/auth/register/trainer` | Public | Registrasi trainer |
| POST | `/api/v1/auth/register/admin` | Admin | Registrasi admin |
| POST | `/api/v1/auth/login` | Public | Login, return JWT |
| GET | `/api/v1/auth/me` | Authenticated | Get current user profile |
| POST | `/api/v1/auth/refresh` | Authenticated | Refresh JWT token |
| POST | `/api/v1/auth/logout` | Authenticated | Invalidate token (optional blacklist) |

### 6.3 Users

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/users` | Admin | List semua user (pagination, filter) |
| GET | `/api/v1/users/:id` | Admin/Self | Detail user |
| PUT | `/api/v1/users/:id` | Admin/Self | Update user |
| DELETE | `/api/v1/users/:id` | Admin | Hapus user |
| GET | `/api/v1/users/email/:email` | Admin | Cari user by email |

### 6.4 Trainers

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/trainers` | Public | List trainer (pagination, search by nama) |
| GET | `/api/v1/trainers/:id` | Public | Detail trainer |
| GET | `/api/v1/trainers/:id/sessions` | Public | Sesi yang ditawarkan trainer |
| PUT | `/api/v1/trainers/:id` | Trainer/Admin/Self | Update profil trainer |

### 6.5 Sessions

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/sessions` | Public | List sesi (pagination, filter: trainer_id, status, search) |
| GET | `/api/v1/sessions/upcoming` | Public | Sesi mendatang |
| GET | `/api/v1/sessions/:id` | Public | Detail sesi |
| POST | `/api/v1/sessions` | Trainer/Admin | Buat sesi |
| PUT | `/api/v1/sessions/:id` | Trainer/Admin (owner) | Update sesi |
| DELETE | `/api/v1/sessions/:id` | Trainer/Admin (owner) | Hapus sesi |

### 6.6 Bookings

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/bookings` | Admin | Semua booking (pagination, filter: status, payment_status) |
| GET | `/api/v1/bookings/my` | Customer/Trainer | Booking saya (customer) / booking sesi saya (trainer) |
| GET | `/api/v1/bookings/:id` | Admin/Owner | Detail booking |
| POST | `/api/v1/bookings` | Customer | Buat booking baru |
| PATCH | `/api/v1/bookings/:id/status` | Admin/Owner | Update status booking |

### 6.7 Payments

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/v1/payments/create` | Authenticated | Buat transaksi Midtrans |
| GET | `/api/v1/payments/:booking_id/status` | Authenticated | Cek status pembayaran |
| POST | `/api/v1/payments/notification` | Public (webhook) | Webhook dari Midtrans |
| GET | `/api/v1/payments/config` | Public | Client key Midtrans |

### 6.8 Reviews

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/reviews` | Admin | Semua review |
| GET | `/api/v1/reviews/session/:session_id` | Public | Review untuk sesi tertentu |
| POST | `/api/v1/reviews` | Customer | Buat review (harus sudah booking & completed) |
| PUT | `/api/v1/reviews/:id` | Customer (owner) | Update review |
| DELETE | `/api/v1/reviews/:id` | Customer (owner)/Admin | Hapus review |

### 6.9 Progress

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/progress` | Admin | Semua progress |
| GET | `/api/v1/progress/my` | Customer | Progress saya |
| POST | `/api/v1/progress` | Customer | Catat progress |
| PUT | `/api/v1/progress/:id` | Customer (owner) | Update progress |
| DELETE | `/api/v1/progress/:id` | Customer (owner)/Admin | Hapus progress |

### 6.10 Body Progress

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/body-progress/my` | Customer | Body progress saya |
| POST | `/api/v1/body-progress` | Customer | Catat body progress |
| DELETE | `/api/v1/body-progress/:id` | Customer (owner) | Hapus |

### 6.11 Analytics

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/analytics/dashboard` | Admin | Statistik dashboard (users, bookings, sessions, revenue) |
| GET | `/api/v1/analytics/users` | Admin | User stats (by role, by kota) |
| GET | `/api/v1/analytics/bookings` | Admin | Booking stats (by status, by month) |
| GET | `/api/v1/analytics/sessions` | Admin | Session stats (by status, by trainer) |

### 6.12 Articles

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/articles` | Public | List artikel (filter: kategori, is_published, search) |
| GET | `/api/v1/articles/:id` | Public | Detail artikel |
| POST | `/api/v1/articles` | Admin | Buat artikel |
| PUT | `/api/v1/articles/:id` | Admin | Update artikel |
| DELETE | `/api/v1/articles/:id` | Admin | Hapus artikel |

### 6.13 Promo

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/promo` | Admin | List semua promo |
| GET | `/api/v1/promo/check` | Public | Cek kode promo valid |
| GET | `/api/v1/promo/:id` | Admin | Detail promo |
| POST | `/api/v1/promo` | Admin | Buat promo |
| PUT | `/api/v1/promo/:id` | Admin | Update promo |
| DELETE | `/api/v1/promo/:id` | Admin | Hapus promo |

### 6.14 Banners

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/banners` | Public | List banner (filter: is_active) |
| POST | `/api/v1/banners` | Admin | Buat banner |
| PUT | `/api/v1/banners/:id` | Admin | Update banner |
| DELETE | `/api/v1/banners/:id` | Admin | Hapus banner |

### 6.15 FAQ

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/faq` | Public | List FAQ (filter: kategori, is_active) |
| POST | `/api/v1/faq` | Admin | Buat FAQ |
| PUT | `/api/v1/faq/:id` | Admin | Update FAQ |
| DELETE | `/api/v1/faq/:id` | Admin | Hapus FAQ |

### 6.16 Notifications

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/notifications` | Admin | Semua notifikasi (pagination, filter: is_read) |
| GET | `/api/v1/notifications/my` | Authenticated | Notifikasi saya |
| POST | `/api/v1/notifications/send` | Admin | Kirim notifikasi ke user |
| PATCH | `/api/v1/notifications/:id/read` | Authenticated (owner) | Tandai sudah dibaca |
| PATCH | `/api/v1/notifications/read-all` | Authenticated | Tandai semua sudah dibaca |
| DELETE | `/api/v1/notifications/:id` | Admin/Owner | Hapus notifikasi |

### 6.17 Upload

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/v1/upload/profile` | Authenticated | Upload foto profil (multipart, max 2MB) |

### 6.18 Views (Aggregated/Joined Data)

Endpoint ini menyediakan data yang sudah di-join/agregate untuk konsumsi frontend:

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/v1/views/customer-booking-history` | Authenticated | Riwayat booking (role-based) |
| GET | `/api/v1/views/customer-booking-history/:id` | Admin/Self | Riwayat booking user tertentu |
| GET | `/api/v1/views/matched-trainer-customer` | Trainer/Admin | Matching trainer-customer |
| GET | `/api/v1/views/progress-summary` | Trainer/Admin | Summary progress semua member |
| GET | `/api/v1/views/progress-summary/:id` | Admin/Self | Progress summary user tertentu |
| GET | `/api/v1/views/trainer-schedule` | Trainer/Admin | Jadwal trainer (role-based) |
| GET | `/api/v1/views/trainer-schedule/:id` | Trainer/Admin/Self | Jadwal trainer tertentu |
| GET | `/api/v1/views/upcoming-sessions` | Authenticated | Sesi mendatang untuk member |
| GET | `/api/v1/views/session-participants` | Trainer/Admin | Peserta semua sesi |
| GET | `/api/v1/views/session-participants/:id` | Trainer/Admin | Peserta sesi tertentu |
| GET | `/api/v1/views/session-reviews` | Public | Review semua sesi |
| GET | `/api/v1/views/session-reviews/:id` | Public | Review sesi tertentu |

---

## 7. Roles & Access Control

### 7.1 Role Definitions

| Role | Deskripsi | Hak Akses Umum |
|------|-----------|----------------|
| **customer** | Member/pengguna biasa | Booking sesi, pembayaran, lihat progress sendiri, review sesi yang sudah completed, update profil sendiri |
| **trainer** | Personal trainer | Buat/kelola sesi sendiri, lihat booking untuk sesi sendiri, lihat progress member yang booking sesinya, update profil sendiri |
| **admin** | Administrator platform | Akses penuh ke semua resource: users, sessions, bookings, articles, promo, banners, FAQ, notifications, analytics |

### 7.2 Access Matrix

| Resource | Customer | Trainer | Admin |
|----------|----------|---------|-------|
| **Users** — list | ❌ | ❌ | ✅ |
| **Users** — read self | ✅ | ✅ | ✅ |
| **Users** — read other | ❌ | ❌ | ✅ |
| **Users** — update self | ✅ | ✅ | ✅ |
| **Users** — delete | ❌ | ❌ | ✅ |
| **Sessions** — list | ✅ | ✅ | ✅ |
| **Sessions** — create | ❌ | ✅ (own) | ✅ |
| **Sessions** — update | ❌ | ✅ (own) | ✅ |
| **Sessions** — delete | ❌ | ✅ (own) | ✅ |
| **Bookings** — list all | ❌ | ❌ | ✅ |
| **Bookings** — list own | ✅ | ✅ (own sessions) | ✅ |
| **Bookings** — create | ✅ | ❌ | ✅ |
| **Bookings** — update status | ❌ | ✅ (own sessions) | ✅ |
| **Reviews** — create | ✅ (own bookings) | ❌ | ✅ |
| **Reviews** — delete | ✅ (own) | ❌ | ✅ |
| **Progress** — list all | ❌ | ✅ (own members) | ✅ |
| **Progress** — list own | ✅ | ❌ | ✅ |
| **Progress** — create | ✅ | ❌ | ✅ |
| **Analytics** | ❌ | ❌ | ✅ |
| **Articles** — CRUD | ❌ | ❌ | ✅ |
| **Promo** — CRUD | ❌ | ❌ | ✅ |
| **Banners** — CRUD | ❌ | ❌ | ✅ |
| **FAQ** — CRUD | ❌ | ❌ | ✅ |
| **Notifications** — send | ❌ | ❌ | ✅ |
| **Notifications** — read own | ✅ | ✅ | ✅ |

### 7.3 Middleware RBAC

```typescript
// Contoh penggunaan
router.get('/users', auth, requireRole('admin'), userController.list);
router.put('/sessions/:id', auth, requireRole('trainer', 'admin'), sessionController.update);
router.delete('/bookings/:id', auth, requireOwnershipOrRole('admin'), bookingController.delete);
```

---

## 8. Validation Strategy

### 8.1 Zod Schema per Module

Setiap module memiliki file `*.schema.ts` yang mendefinisikan validasi untuk:

- **Body** — request body (create/update)
- **Params** — URL params (e.g., `id` must be positive integer)
- **Query** — query string (pagination, filter, sort)

```typescript
// Contoh: session.schema.ts
export const createSessionSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(100),
    description: z.string().optional(),
    trainer_id: z.number().int().positive(),
    start_time: z.string().datetime(),
    end_time: z.string().datetime().optional(),
    price: z.number().nonnegative().default(0),
    max_participants: z.number().int().positive().default(1),
  }),
});

export const listSessionsQuerySchema = z.object({
  query: z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().positive().max(100).default(20),
    search: z.string().optional(),
    trainer_id: z.coerce.number().int().positive().optional(),
    status: z.enum(['scheduled', 'ongoing', 'completed', 'cancelled']).optional(),
    sort: z.enum(['created_at', 'start_time', 'price']).default('start_time'),
    order: z.enum(['asc', 'desc']).default('asc'),
  }),
});
```

### 8.2 Validation Middleware

```typescript
// Generic validate middleware
export function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse({ body: req.body, params: req.params, query: req.query });
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Input tidak valid', details: result.error.issues }
      });
    }
    req.validated = result.data;
    next();
  };
}
```

---

## 9. Drizzle ORM Setup

### 9.1 Schema Definition

```typescript
// src/db/schema/users.ts
import { pgTable, serial, varchar, text, date, char, timestamp, boolean, pgEnum } from 'drizzle-orm/pg-core';

export const roleEnum = pgEnum('user_role', ['customer', 'trainer', 'admin']);

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  nama: varchar('nama', { length: 100 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),
  role: roleEnum('role').notNull().default('customer'),
  jenis_kelamin: char('jenis_kelamin', { length: 1 }),
  no_telp: varchar('no_telp', { length: 20 }),
  tanggal_lahir: date('tanggal_lahir'),
  foto: varchar('foto', { length: 255 }),
  bio: text('bio'),
  propinsi: varchar('propinsi', { length: 45 }).default(''),
  kota: varchar('kota', { length: 45 }).default(''),
  spesialisasi: varchar('spesialisasi', { length: 100 }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }),
});
```

### 9.2 Client Setup

```typescript
// src/db/client.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // atau individual config
});

export const db = drizzle(pool, { schema });
export type DB = typeof db;
```

### 9.3 Migration

```bash
# Generate migration dari schema changes
npx drizzle-kit generate

# Run migration
npx drizzle-kit migrate

# Studio (GUI untuk inspect database)
npx drizzle-kit studio
```

### 9.4 Drizzle Config

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema/index.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

- API response time < 200ms untuk query sederhana (P95)
- API response time < 500ms untuk query dengan JOIN/aggregation (P95)
- Database connection pool: min 2, max 10 connections
- Cache TTL: 5-10 menit untuk read-heavy data (trainers list, banners, FAQ)

### 10.2 Security

- Password hashing: bcrypt (salt rounds 10)
- JWT expiry: 7 days
- Rate limiting: 100 requests per 15 minutes per IP (global), 5 requests per minute untuk auth endpoints
- Helmet untuk security headers
- CORS whitelist berdasarkan `FRONTEND_URL` env var
- Input validation via Zod untuk semua endpoint
- SQL injection prevention via Drizzle parameterized queries

### 10.3 Reliability

- Graceful shutdown: close DB pool sebelum exit
- Health check endpoint: `/api/health` → `{ status: "ok", db: true/false }`
- Retry logic untuk DB connection pada startup (max 10 retries, 5s interval)
- Structured logging via Pino (request ID, timestamp, level, message)

### 10.4 Observability

- Request logging: method, path, status, duration
- Error logging: stack trace, request context
- DB query logging (development mode only)

---

## 11. Migration Plan (Schema Lama → Baru)

### 11.1 Langkah-langkah

1. **Buat schema baru** via Drizzle (migrate ke PostgreSQL database fresh)
2. **Seed data** — jalankan `seed.ts` untuk data awal (admin, trainers, FAQ, articles, promo, sessions)
3. **Data migration script** (opsional) — jika ada data production yang perlu dipindahkan, buat script yang:
   - Baca dari MySQL lama
   - Transform nama kolom (`deskripsi` → `description`, `is_read` 0/1 → false/true, dst)
   - Insert ke PostgreSQL baru via Drizzle
4. **Test API endpoints** — verify semua endpoint berfungsi
5. **Update frontend** — adaptasi API contract baru (phase berikutnya)
6. **Update mobile** — adaptasi API contract baru (phase berikutnya)

### 11.2 Breaking Changes untuk Frontend/Mobile

| Aspek | Lama | Baru | Impact |
|-------|------|------|--------|
| API prefix | `/api/` | `/api/v1/` | Update base URL |
| Response format | Inconsistent | Unified `{ success, data, message, meta }` | Update response parsing |
| Error format | `{ message: "..." }` | `{ success: false, error: { code, message, details } }` | Update error handling |
| Boolean fields | `0`/`1` (integer) | `true`/`false` (boolean) | Update type checks |
| Booking status | `Pending`, `Confirmed` (PascalCase) | `pending`, `confirmed` (lowercase) | Update string comparisons |
| Session description | `deskripsi` | `description` | Update field name |
| Pagination | `X-Total-Count` header | `meta` object in response body | Update pagination logic |

---

## 12. Testing Strategy

### 12.1 Unit Tests

- **Service layer** — mock repo, test business logic
- **Validation** — test Zod schemas dengan valid/invalid input
- **Middleware** — test auth, role, error handler

### 12.2 Integration Tests

- **Repo layer** — test Drizzle queries terhadap test database (PostgreSQL)
- **Controller** — test HTTP request/response dengan supertest

### 12.3 E2E Tests (Optional)

- Full flow: register → login → book session → pay → review
- Admin flow: login → create article → verify public can read

---

## 13. Implementation Phases & Task Breakdown

> Setiap phase harus selesai sepenuhnya sebelum lanjut ke phase berikutnya.
> Setiap task ditandai `[ ]` dan di-check `[x]` saat selesai.

---

### Phase 1: Project Setup & Infrastructure

**Tujuan:** Setup foundation — dependencies, config, Drizzle schema, database connection, shared utilities, middleware, dan Express app shell.

#### 1.1 Install Dependencies
- [ ] Install runtime deps: `drizzle-orm`, `zod`, `pino`, `pino-http`
- [ ] Install dev deps: `drizzle-kit`, `tsx` (untuk run TS scripts)
- [ ] Remove old deps: `mariadb`, `mysql2`, `mongoose`, `sequelize`, `express-mysql-session`, `express-session`
- [ ] Update `package.json` scripts: `dev`, `start`, `db:generate`, `db:migrate`, `db:seed`, `db:studio`
- [ ] Verify `npm install` clean (0 vulnerabilities)

#### 1.2 Environment Config
- [ ] Buat `src/config/env.ts` — centralized env config dengan Zod validation (DATABASE_URL, JWT_SECRET, PORT, MIDTRANS keys, FRONTEND_URL, DB_SSL)
- [ ] Update `.env.example` dengan format PostgreSQL (DATABASE_URL + individual vars)
- [ ] Buat `drizzle.config.ts` di root backend

#### 1.3 Drizzle Schema Definitions
- [ ] `src/db/schema/users.ts` — tabel `users` + enum `user_role`
- [ ] `src/db/schema/sessions.ts` — tabel `sessions` + enum `session_status`
- [ ] `src/db/schema/bookings.ts` — tabel `bookings` + enum `booking_status`, `payment_status`
- [ ] `src/db/schema/reviews.ts` — tabel `reviews`
- [ ] `src/db/schema/progress.ts` — tabel `progress`
- [ ] `src/db/schema/bodyProgress.ts` — tabel `body_progress`
- [ ] `src/db/schema/notifications.ts` — tabel `notifications` + enum `notification_type`
- [ ] `src/db/schema/articles.ts` — tabel `articles` + enum `article_kategori`
- [ ] `src/db/schema/promo.ts` — tabel `promo` + enum `promo_tipe`
- [ ] `src/db/schema/banners.ts` — tabel `banners`
- [ ] `src/db/schema/faq.ts` — tabel `faq`
- [ ] `src/db/schema/reminders.ts` — tabel `reminders` + enum `reminder_tipe`
- [ ] `src/db/schema/dietPrograms.ts` — tabel `diet_programs` + enum `diet_tipe`
- [ ] `src/db/schema/index.ts` — re-export semua schema + relations
- [ ] Generate migration: `npx drizzle-kit generate`
- [ ] Run migration ke database: `npx drizzle-kit migrate`

#### 1.4 Database Client & Seed
- [ ] `src/db/client.ts` — Drizzle client (Pool + drizzle() + schema)
- [ ] `src/db/seed.ts` — Seed data: admin, 3 trainers, 1 customer, FAQ, articles, promo, sample sessions
- [ ] Jalankan seed: `npm run db:seed`
- [ ] Verify data via `drizzle-kit studio`

#### 1.5 Shared Utilities
- [ ] `src/utils/logger.ts` — Pino logger (dev: pretty, prod: JSON)
- [ ] `src/utils/response.ts` — `success()`, `error()`, `paginated()` helpers (unified format)
- [ ] `src/utils/jwt.ts` — `signToken()`, `verifyToken()`
- [ ] `src/utils/cache.ts` — re-export node-cache (dari existing)

#### 1.6 Middleware
- [ ] `src/middleware/auth.ts` — JWT verification, attach `req.user`
- [ ] `src/middleware/role.ts` — `requireRole(...roles)`, `requireOwnershipOrRole(role)` (cek `req.params.id === req.user.id`)
- [ ] `src/middleware/validate.ts` — generic Zod validation middleware
- [ ] `src/middleware/error.ts` — global error handler (catch all, format response)
- [ ] `src/middleware/notFound.ts` — 404 handler
- [ ] `src/middleware/upload.ts` — Multer config (dari existing, rename)

#### 1.7 Express App Shell
- [ ] `src/app.ts` — Express app setup: helmet, cors, compression, rate-limit, pino-http, JSON body parser, static uploads, health check route, mount semua route modules di `/api/v1/`, 404 + error handler
- [ ] Update `server.js` — import app, connect DB (retry logic), graceful shutdown, listen
- [ ] Test: `npm run dev` → server starts, `/api/health` returns `{ status: "ok", db: true }`

**Acceptance Criteria Phase 1:**
- Server starts tanpa error
- Database connected dan migrated
- Seed data ter-load
- `/api/health` endpoint berfungsi
- Global error handler menangkap unhandled errors

---

### Phase 2: Auth & User Modules

**Tujuan:** Implement authentication (register, login, JWT) dan user management (CRUD, profile).

#### 2.1 Auth Module
- [ ] `src/modules/auth/auth.schema.ts` — Zod schemas: registerCustomer, registerTrainer, registerAdmin, login
- [ ] `src/modules/auth/auth.repo.ts` — repo functions: `findUserByEmail`, `createUser`
- [ ] `src/modules/auth/auth.service.ts` — business logic: `registerCustomer()`, `registerTrainer()`, `registerAdmin()`, `login()`, `getMe()`
  - Password hashing (bcrypt, salt 10)
  - JWT generation (7d expiry)
  - Error handling: email conflict → 409, invalid credentials → 401
- [ ] `src/modules/auth/auth.controller.ts` — HTTP handlers: parse req, validate, call service, format response
- [ ] `src/modules/auth/auth.routes.ts` — routes: POST `/register`, POST `/register/trainer`, POST `/register/admin`, POST `/login`, GET `/me`
- [ ] Mount di `app.ts`: `/api/v1/auth`
- [ ] Test: register customer → login → GET `/me` → verify response

#### 2.2 User Module
- [ ] `src/modules/user/user.schema.ts` — Zod schemas: updateUser, listUsersQuery, idParam
- [ ] `src/modules/user/user.repo.ts` — `findAll` (pagination+filter), `findById`, `findByEmail`, `updateUser`, `deleteUser`
- [ ] `src/modules/user/user.service.ts` — `listUsers()`, `getUserById()`, `getUserByEmail()`, `updateUser()`, `deleteUser()` dengan role checks
- [ ] `src/modules/user/user.controller.ts` — HTTP handlers
- [ ] `src/modules/user/user.routes.ts` — GET `/`, GET `/:id`, PUT `/:id`, GET `/email/:email`, DELETE `/:id`, GET+PUT `/profile` (self)
- [ ] Mount di `app.ts`: `/api/v1/users`
- [ ] Test: admin list users, user update own profile, admin delete user

**Acceptance Criteria Phase 2:**
- Register 3 roles (customer, trainer, admin) berfungsi
- Login return JWT
- GET `/me` dengan token return user data
- Admin bisa list/delete users
- User bisa update profil sendiri
- Email duplicate → 409 CONFLICT
- Invalid credentials → 401 UNAUTHORIZED

---

### Phase 3: Session & Trainer Modules

**Tujuan:** Implement session CRUD dan trainer profile management.

#### 3.1 Session Module
- [ ] `src/modules/session/session.schema.ts` — createSession, updateSession, listSessionsQuery, idParam
- [ ] `src/modules/session/session.repo.ts` — `findAll` (pagination+filter+JOIN trainer), `findById` (JOIN trainer), `findUpcoming`, `create`, `update`, `delete`, `isOwner(trainerId, sessionId)`
- [ ] `src/modules/session/session.service.ts` — `listSessions()`, `getSessionById()`, `getUpcomingSessions()`, `createSession()`, `updateSession()` (ownership check), `deleteSession()` (ownership check + cascade booking check)
- [ ] `src/modules/session/session.controller.ts`
- [ ] `src/modules/session/session.routes.ts` — GET `/`, GET `/upcoming`, GET `/:id`, POST `/` (trainer/admin), PUT `/:id` (trainer/admin+owner), DELETE `/:id` (trainer/admin+owner)
- [ ] Mount di `app.ts`: `/api/v1/sessions`
- [ ] Test: trainer create session, public list sessions, trainer update own session, admin delete any session

#### 3.2 Trainer Module
- [ ] `src/modules/trainer/trainer.schema.ts` — listTrainersQuery, updateTrainer, idParam
- [ ] `src/modules/trainer/trainer.repo.ts` — `findAllTrainers` (pagination+search, role=trainer), `findTrainerById`, `findTrainerByName`, `updateTrainer`, `getTrainerSessions`
- [ ] `src/modules/trainer/trainer.service.ts` — `listTrainers()`, `getTrainerById()`, `getTrainerByName()`, `updateTrainer()` (ownership check), `getTrainerSessions()`
- [ ] `src/modules/trainer/trainer.controller.ts`
- [ ] `src/modules/trainer/trainer.routes.ts` — GET `/`, GET `/:id`, GET `/:id/sessions`, PUT `/:id` (trainer/admin+self)
- [ ] Mount di `app.ts`: `/api/v1/trainers`
- [ ] Test: public list trainers, trainer update own profile, public get trainer sessions

**Acceptance Criteria Phase 3:**
- Trainer bisa CRUD sesi sendiri
- Public bisa lihat sesi & trainer
- Admin bisa manage semua sesi
- Ownership enforcement: trainer tidak bisa edit sesi trainer lain
- Pagination & filtering berfungsi

---

### Phase 4: Booking & Payment Modules

**Tujuan:** Implement booking system dan Midtrans payment integration.

#### 4.1 Booking Module
- [ ] `src/modules/booking/booking.schema.ts` — createBooking, updateBookingStatus, listBookingsQuery, idParam
- [ ] `src/modules/booking/booking.repo.ts` — `findAll` (pagination+filter+JOIN session+user), `findById` (JOIN), `findByMember` (my bookings), `findBySessionTrainer` (trainer bookings), `create`, `updateStatus`, `checkExistingBooking` (unique session+member)
- [ ] `src/modules/booking/booking.service.ts` — `listBookings()`, `getBookingById()`, `getMyBookings()` (role-based: customer=own, trainer=own sessions), `createBooking()` (check duplicate, check session exists, check max_participants), `updateBookingStatus()` (ownership/role check)
- [ ] `src/modules/booking/booking.controller.ts`
- [ ] `src/modules/booking/booking.routes.ts` — GET `/` (admin), GET `/my` (auth), GET `/:id` (auth+owner/admin), POST `/` (customer), PATCH `/:id/status` (trainer/admin+owner)
- [ ] Mount di `app.ts`: `/api/v1/bookings`
- [ ] Test: customer create booking, customer view my bookings, trainer view own session bookings, admin view all, update status

#### 4.2 Payment Module
- [ ] `src/modules/payment/payment.schema.ts` — createPayment, idParam
- [ ] `src/modules/payment/payment.repo.ts` — `findBookingForPayment` (by id, JOIN session), `updatePaymentStatus`, `updateMidtransInfo`, `createNotification`
- [ ] `src/modules/payment/payment.service.ts` — `createPayment()` (Midtrans Snap token), `handleNotification()` (webhook: verify signature, update status, send notification), `checkPaymentStatus()`, `getPaymentConfig()`
- [ ] `src/modules/payment/payment.controller.ts`
- [ ] `src/modules/payment/payment.routes.ts` — POST `/create` (auth), GET `/:booking_id/status` (auth), POST `/notification` (public webhook), GET `/config` (public)
- [ ] Mount di `app.ts`: `/api/v1/payments`
- [ ] Test: create payment → get Snap token, webhook simulation, check status

**Acceptance Criteria Phase 4:**
- Customer bisa booking sesi (no double booking)
- Customer bisa bayar via Midtrans Snap
- Webhook update status pembayaran
- Trainer bisa update booking status (confirmed/completed/cancelled)
- Admin bisa lihat semua booking
- Role-based booking list (my bookings) berfungsi

---

### Phase 5: Review & Progress Modules

**Tujuan:** Implement review system dan progress tracking (activity + body progress).

#### 5.1 Review Module
- [ ] `src/modules/review/review.schema.ts` — createReview, updateReview, idParam, sessionIdParam
- [ ] `src/modules/review/review.repo.ts` — `findAll` (JOIN user+session), `findBySession` (JOIN user), `findById`, `create`, `update`, `delete`, `checkExistingReview` (one review per session per member), `checkBookingCompleted` (must have completed booking)
- [ ] `src/modules/review/review.service.ts` — `listReviews()`, `getSessionReviews()`, `createReview()` (validate: booking exists & completed, no existing review), `updateReview()` (ownership), `deleteReview()` (ownership/admin)
- [ ] `src/modules/review/review.controller.ts`
- [ ] `src/modules/review/review.routes.ts` — GET `/` (admin), GET `/session/:session_id` (public), POST `/` (customer), PUT `/:id` (customer+owner), DELETE `/:id` (customer+owner/admin)
- [ ] Mount di `app.ts`: `/api/v1/reviews`
- [ ] Test: customer create review after completed booking, public view session reviews, customer delete own review

#### 5.2 Progress Module
- [ ] `src/modules/progress/progress.schema.ts` — createProgress, updateProgress, idParam
- [ ] `src/modules/progress/progress.repo.ts` — `findAll` (JOIN user), `findByMember`, `findById`, `create`, `update`, `delete`
- [ ] `src/modules/progress/progress.service.ts` — `listProgress()`, `getMyProgress()`, `createProgress()`, `updateProgress()` (ownership), `deleteProgress()` (ownership/admin)
- [ ] `src/modules/progress/progress.controller.ts`
- [ ] `src/modules/progress/progress.routes.ts` — GET `/` (admin), GET `/my` (auth), POST `/` (customer), PUT `/:id` (customer+owner), DELETE `/:id` (customer+owner/admin)
- [ ] Mount di `app.ts`: `/api/v1/progress`

#### 5.3 Body Progress Module
- [ ] `src/modules/progress/bodyProgress.schema.ts` — createBodyProgress, idParam
- [ ] `src/modules/progress/bodyProgress.repo.ts` — `findByMember`, `create`, `delete`
- [ ] `src/modules/progress/bodyProgress.service.ts` — `getMyBodyProgress()`, `createBodyProgress()` (auto-calculate BMI if berat+tinggi provided), `deleteBodyProgress()` (ownership)
- [ ] `src/modules/progress/bodyProgress.controller.ts`
- [ ] `src/modules/progress/bodyProgress.routes.ts` — GET `/my`, POST `/`, DELETE `/:id`
- [ ] Mount di `app.ts`: `/api/v1/body-progress`
- [ ] Test: customer create progress, customer create body progress with BMI auto-calc, delete own progress

**Acceptance Criteria Phase 5:**
- Customer bisa catat progress latihan
- Customer bisa catat body progress (BMI auto-calc)
- Customer hanya bisa lihat/edit progress sendiri
- Review hanya bisa dibuat jika booking completed
- Public bisa lihat review sesi

---

### Phase 6: Admin Content Modules

**Tujuan:** Implement semua admin-managed content: articles, promo, banners, FAQ, notifications, upload.

#### 6.1 Article Module
- [ ] `src/modules/article/article.schema.ts` — createArticle, updateArticle, listArticlesQuery, idParam
- [ ] `src/modules/article/article.repo.ts` — `findAll` (pagination+filter+JOIN author), `findById`, `create`, `update`, `delete`
- [ ] `src/modules/article/article.service.ts` — `listArticles()`, `getArticleById()`, `createArticle()`, `updateArticle()`, `deleteArticle()` + cache invalidation
- [ ] `src/modules/article/article.controller.ts`
- [ ] `src/modules/article/article.routes.ts` — GET `/` (public), GET `/:id` (public), POST `/` (admin), PUT `/:id` (admin), DELETE `/:id` (admin)
- [ ] Mount di `app.ts`: `/api/v1/articles`

#### 6.2 Promo Module
- [ ] `src/modules/promo/promo.schema.ts` — createPromo, updatePromo, listPromoQuery, idParam, checkPromoQuery
- [ ] `src/modules/promo/promo.repo.ts` — `findAll`, `findById`, `findByCode` (active+valid date range), `create`, `update`, `delete`
- [ ] `src/modules/promo/promo.service.ts` — `listPromo()`, `getPromoById()`, `checkPromoByCode()`, `createPromo()` (unique kode check), `updatePromo()`, `deletePromo()` + cache
- [ ] `src/modules/promo/promo.controller.ts`
- [ ] `src/modules/promo/promo.routes.ts` — GET `/` (admin), GET `/check` (public), GET `/:id` (admin), POST `/` (admin), PUT `/:id` (admin), DELETE `/:id` (admin)
- [ ] Mount di `app.ts`: `/api/v1/promo`

#### 6.3 Banner Module
- [ ] `src/modules/banner/banner.schema.ts` — createBanner, updateBanner, idParam
- [ ] `src/modules/banner/banner.repo.ts` — `findAll` (filter is_active), `create`, `update`, `delete`
- [ ] `src/modules/banner/banner.service.ts` — `listBanners()`, `createBanner()`, `updateBanner()`, `deleteBanner()` + cache
- [ ] `src/modules/banner/banner.controller.ts`
- [ ] `src/modules/banner/banner.routes.ts` — GET `/` (public), POST `/` (admin), PUT `/:id` (admin), DELETE `/:id` (admin)
- [ ] Mount di `app.ts`: `/api/v1/banners`

#### 6.4 FAQ Module
- [ ] `src/modules/faq/faq.schema.ts` — createFaq, updateFaq, idParam, listFaqQuery
- [ ] `src/modules/faq/faq.repo.ts` — `findAll` (filter kategori+is_active, order by urutan), `create`, `update`, `delete`
- [ ] `src/modules/faq/faq.service.ts` — `listFaq()`, `createFaq()`, `updateFaq()`, `deleteFaq()` + cache
- [ ] `src/modules/faq/faq.controller.ts`
- [ ] `src/modules/faq/faq.routes.ts` — GET `/` (public), POST `/` (admin), PUT `/:id` (admin), DELETE `/:id` (admin)
- [ ] Mount di `app.ts`: `/api/v1/faq`

#### 6.5 Notification Module
- [ ] `src/modules/notification/notification.schema.ts` — sendNotification, idParam, listNotificationsQuery
- [ ] `src/modules/notification/notification.repo.ts` — `findAll` (pagination+filter is_read), `findByUser` (limit 50), `countUnread`, `create`, `markAsRead`, `markAllAsRead`, `delete`
- [ ] `src/modules/notification/notification.service.ts` — `listNotifications()`, `getMyNotifications()`, `sendNotification()` (validate user_id exists), `markAsRead()` (ownership), `markAllAsRead()`, `deleteNotification()` (ownership/admin)
- [ ] `src/modules/notification/notification.controller.ts`
- [ ] `src/modules/notification/notification.routes.ts` — GET `/` (admin), GET `/my` (auth), POST `/send` (admin), PATCH `/:id/read` (auth+owner), PATCH `/read-all` (auth), DELETE `/:id` (auth+owner/admin)
- [ ] Mount di `app.ts`: `/api/v1/notifications`

#### 6.6 Upload Module
- [ ] `src/modules/upload/upload.routes.ts` — POST `/profile` (auth, multer single 'foto', max 2MB, update user.foto in DB, return path+URL)
- [ ] Reuse `src/middleware/upload.ts` dari Phase 1
- [ ] Mount di `app.ts`: `/api/v1/upload`
- [ ] Test: upload foto profil, verify URL accessible

**Acceptance Criteria Phase 6:**
- Admin bisa CRUD articles, promo, banners, FAQ
- Public bisa lihat articles (published), banners (active), FAQ (active), cek kode promo
- Admin bisa kirim notifikasi ke user tertentu
- User bisa lihat & mark read notifikasi sendiri
- Upload foto profil berfungsi

---

### Phase 7: Analytics Module

**Tujuan:** Implement dashboard analytics untuk admin.

#### 7.1 Analytics Module
- [ ] `src/modules/analytics/analytics.repo.ts` — `getUserStats` (total by role, by kota), `getBookingStats` (total by status, by payment_status, by month), `getSessionStats` (total by status, by trainer), `getDashboardStats` (aggregate: total users, sessions, bookings, revenue, recent bookings, recent users)
- [ ] `src/modules/analytics/analytics.service.ts` — `getDashboard()`, `getUserStats()`, `getBookingStats()`, `getSessionStats()` + cache (TTL 5 min)
- [ ] `src/modules/analytics/analytics.controller.ts`
- [ ] `src/modules/analytics/analytics.routes.ts` — GET `/dashboard`, GET `/users`, GET `/bookings`, GET `/sessions` (all admin)
- [ ] Mount di `app.ts`: `/api/v1/analytics`
- [ ] Test: admin GET dashboard → verify stats correct

**Acceptance Criteria Phase 7:**
- Dashboard return: total users (by role), total sessions, total bookings (by status), revenue
- Recent bookings & users list
- All endpoints admin-only

---

### Phase 8: Views Module (Aggregated Data)

**Tujuan:** Implement semua endpoint yang menyajikan data joined/aggregated untuk frontend.

#### 8.1 Views Module
- [ ] `src/modules/views/views.repo.ts` — repo functions untuk semua view queries:
  - `customerBookingHistory` (JOIN booking+session+user+trainer)
  - `customerBookingHistoryById` (filter by member_id)
  - `trainerBookingHistory` (filter by session.trainer_id)
  - `matchedTrainerCustomer` (status=confirmed)
  - `memberProgressSummary` (JOIN progress+user)
  - `memberProgressSummaryById` (filter by member_id)
  - `trainerSchedule` (sessions by trainer_id + confirmed count)
  - `upcomingSessions` (start_time > now + confirmed/total count)
  - `sessionParticipants` (JOIN booking+session+user, optional filter by session_id)
  - `sessionReviewsSummary` (JOIN reviews+session+user+trainer, optional filter by session_id)
- [ ] `src/modules/views/views.service.ts` — role-based logic untuk setiap view + cache
- [ ] `src/modules/views/views.controller.ts`
- [ ] `src/modules/views/views.routes.ts` — semua endpoint dari section 6.18 PRD
- [ ] Mount di `app.ts`: `/api/v1/views`
- [ ] Test: setiap endpoint return data correct berdasarkan role

**Acceptance Criteria Phase 8:**
- Customer lihat booking history sendiri
- Trainer lihat booking untuk sesi sendiri
- Admin lihat semua
- Upcoming sessions untuk member
- Session participants & reviews summary berfungsi
- Role-based access enforcement di setiap endpoint

---

### Phase 9: Testing & Polish

**Tujuan:** Testing, error handling audit, performance optimization, dan dokumentasi.

#### 9.1 Error Handling Audit
- [ ] Audit semua controller — pastikan try/catch konsisten
- [ ] Audit semua service — pastikan error throw dengan code yang benar
- [ ] Verify global error handler menangkap semua unhandled errors
- [ ] Test: hit endpoint dengan invalid ID → 404, invalid body → 400, no token → 401, wrong role → 403

#### 9.2 Performance Optimization
- [ ] Identify & fix N+1 queries (gunakan Drizzle JOIN atau batch queries)
- [ ] Add database indexes untuk kolom yang sering di-filter (role, status, member_id, trainer_id, session_id)
- [ ] Verify cache strategy: trainers list, banners, FAQ, articles list, analytics dashboard
- [ ] Test: response time < 200ms untuk simple queries, < 500ms untuk complex queries

#### 9.3 Smoke Test All Endpoints
- [ ] Auth: register 3 roles, login, get me
- [ ] User: list (admin), get by id, update profile, delete
- [ ] Trainer: list, get by id, get sessions, update
- [ ] Session: list, upcoming, get by id, create (trainer), update, delete
- [ ] Booking: create (customer), my bookings, get by id, update status (trainer), list (admin)
- [ ] Payment: create, check status, webhook simulation
- [ ] Review: create (customer), session reviews, delete
- [ ] Progress: create, my progress, delete
- [ ] Body progress: create, my body progress, delete
- [ ] Articles: CRUD (admin), list (public)
- [ ] Promo: CRUD (admin), check code (public)
- [ ] Banners: CRUD (admin), list (public)
- [ ] FAQ: CRUD (admin), list (public)
- [ ] Notifications: send (admin), my notifications, mark read, delete
- [ ] Upload: profile photo
- [ ] Analytics: dashboard, users, bookings, sessions
- [ ] Views: all 12 endpoints

#### 9.4 Documentation
- [ ] Update `TUTOR.md` — tech stack baru, API endpoints baru, setup instructions
- [ ] Update `.env.example` jika ada perubahan
- [ ] Update `package.json` scripts
- [ ] Buat `README.md` singkat untuk backend (setup, run, migrate, seed)

**Acceptance Criteria Phase 9:**
- Semua endpoint berfungsi end-to-end
- Error handling konsisten di semua module
- Tidak ada N+1 queries
- Response time sesuai target
- Dokumentasi updated

---

### Phase 10: Frontend & Mobile Adaptation (Separate Effort)

**Tujuan:** Update Vue frontend dan Flutter mobile untuk adaptasi API contract baru.

#### 10.1 Vue Frontend
- [ ] Update API base URL: `/api/` → `/api/v1/`
- [ ] Update response parsing: `{ success, data, message, meta }` format
- [ ] Update error handling: `{ success: false, error: { code, message } }` format
- [ ] Update boolean field handling: `0/1` → `true/false`
- [ ] Update booking status: PascalCase → lowercase
- [ ] Update session field: `deskripsi` → `description`
- [ ] Update pagination: `X-Total-Count` header → `meta` object
- [ ] Test semua halaman: login, register, dashboard, booking, payment, admin panel

#### 10.2 Flutter Mobile
- [ ] Update API base URL
- [ ] Update model classes (boolean, enum values, field names)
- [ ] Update response parsing
- [ ] Update error handling
- [ ] Test semua screen: auth, home, booking, payment, profile, admin, trainer

**Acceptance Criteria Phase 10:**
- Frontend web berfungsi penuh dengan API baru
- Mobile app berfungsi penuh dengan API baru
- Tidak ada regression

---

## 14. Dependency Graph Antar Phase

```
Phase 1 (Foundation)
  ├── Phase 2 (Auth & User)
  │     ├── Phase 3 (Session & Trainer)
  │     │     ├── Phase 4 (Booking & Payment)
  │     │     │     ├── Phase 5 (Review & Progress)
  │     │     │     └── Phase 7 (Analytics)
  │     │     └── Phase 8 (Views)
  │     └── Phase 6 (Admin Content)
  └── Phase 9 (Testing & Polish) — setelah semua phase 2-8 selesai
        └── Phase 10 (Frontend & Mobile) — setelah Phase 9
```

- Phase 2-8 dapat dikerjakan secara paralel setelah Phase 1 selesai (dalam practice, sequential lebih aman)
- Phase 9 butuh semua module selesai
- Phase 10 butuh backend final

---

## 15. Open Questions

1. **Token refresh** — apakah perlu refresh token mechanism, atau 7-day expiry cukup?
2. **File upload** — tetap local storage, atau langsung integrasi cloud (S3/Cloudinary)?
3. **Notification delivery** — in-app only, atau perlu push notification (FCM/APNs)?
4. **Soft delete** — apakah user/booking perlu soft delete (flag `deleted_at`), atau hard delete cukup?
5. **Rate limiting per user** — apakah perlu rate limit per authenticated user (bukan per IP)?
6. **API versioning** — apakah `/api/v1/` perlu dari awal, atau `/api/` saja cukup?
7. **Diet programs & reminders** — apakah fitur ini masih relevan untuk MVP baru, atau defer?
8. **Body progress** — apakah perlu auto-calculate BMI di backend, atau frontend yang hitung?

---

> **Catatan:** PRD ini adalah living document. Update sesuai hasil diskusi dan discovery selama implementasi.
