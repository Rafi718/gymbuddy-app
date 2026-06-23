CREATE TYPE "public"."article_kategori" AS ENUM('Diet', 'Bulking', 'Cutting', 'Workout', 'Motivasi');--> statement-breakpoint
CREATE TYPE "public"."booking_status" AS ENUM('pending', 'confirmed', 'completed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."diet_tipe" AS ENUM('bulking', 'cutting', 'maintenance');--> statement-breakpoint
CREATE TYPE "public"."notification_type" AS ENUM('booking', 'payment', 'progress', 'promo', 'system');--> statement-breakpoint
CREATE TYPE "public"."payment_status" AS ENUM('pending', 'settlement', 'cancel', 'expire');--> statement-breakpoint
CREATE TYPE "public"."promo_tipe" AS ENUM('persen', 'nominal');--> statement-breakpoint
CREATE TYPE "public"."reminder_tipe" AS ENUM('latihan', 'minum', 'makan', 'tidur', 'custom');--> statement-breakpoint
CREATE TYPE "public"."session_status" AS ENUM('scheduled', 'ongoing', 'completed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."user_role" AS ENUM('customer', 'trainer', 'admin');--> statement-breakpoint
CREATE TABLE "articles" (
	"id" serial PRIMARY KEY NOT NULL,
	"title" varchar(200) NOT NULL,
	"slug" varchar(200) NOT NULL,
	"content" text,
	"excerpt" text,
	"kategori" "article_kategori" DEFAULT 'Workout' NOT NULL,
	"author_id" integer,
	"foto" varchar(255),
	"is_published" boolean DEFAULT false NOT NULL,
	"published_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone,
	CONSTRAINT "articles_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "banners" (
	"id" serial PRIMARY KEY NOT NULL,
	"judul" varchar(200),
	"deskripsi" text,
	"gambar" varchar(255) NOT NULL,
	"link" varchar(255),
	"urutan" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "body_progress" (
	"id" serial PRIMARY KEY NOT NULL,
	"member_id" integer NOT NULL,
	"berat_badan" numeric(5, 2),
	"tinggi_badan" numeric(5, 2),
	"bmi" numeric(4, 2),
	"body_fat" numeric(4, 1),
	"target_berat" numeric(5, 2),
	"foto_before" varchar(255),
	"foto_after" varchar(255),
	"catatan" text,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bookings" (
	"id" serial PRIMARY KEY NOT NULL,
	"session_id" integer NOT NULL,
	"member_id" integer NOT NULL,
	"status" "booking_status" DEFAULT 'pending' NOT NULL,
	"payment_status" "payment_status" DEFAULT 'pending' NOT NULL,
	"payment_method" varchar(50),
	"payment_amount" numeric(10, 2) DEFAULT '0.00' NOT NULL,
	"payment_date" timestamp with time zone,
	"midtrans_transaction_id" varchar(100),
	"midtrans_order_id" varchar(100),
	"midtrans_token" text,
	"catatan" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "diet_programs" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"tipe" "diet_tipe" NOT NULL,
	"target_kalori" integer,
	"target_protein" integer,
	"target_karbohidrat" integer,
	"target_lemak" integer,
	"tanggal_mulai" date,
	"tanggal_selesai" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"catatan" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "faq" (
	"id" serial PRIMARY KEY NOT NULL,
	"pertanyaan" text NOT NULL,
	"jawaban" text NOT NULL,
	"kategori" varchar(50) DEFAULT 'umum' NOT NULL,
	"urutan" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "notifications" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"title" varchar(200) NOT NULL,
	"message" text NOT NULL,
	"type" "notification_type" DEFAULT 'system' NOT NULL,
	"is_read" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "progress" (
	"id" serial PRIMARY KEY NOT NULL,
	"member_id" integer NOT NULL,
	"booking_id" integer,
	"activity" varchar(100) NOT NULL,
	"duration" integer NOT NULL,
	"note" text,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "promo" (
	"id" serial PRIMARY KEY NOT NULL,
	"kode" varchar(50) NOT NULL,
	"judul" varchar(200) NOT NULL,
	"deskripsi" text,
	"tipe" "promo_tipe" DEFAULT 'nominal' NOT NULL,
	"nilai" numeric(10, 2) NOT NULL,
	"min_booking" integer DEFAULT 1 NOT NULL,
	"maks_diskon" numeric(10, 2),
	"kuota" integer,
	"terpakai" integer DEFAULT 0 NOT NULL,
	"tanggal_mulai" timestamp with time zone,
	"tanggal_selesai" timestamp with time zone,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "promo_kode_unique" UNIQUE("kode")
);
--> statement-breakpoint
CREATE TABLE "reminders" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"judul" varchar(200) NOT NULL,
	"tipe" "reminder_tipe" DEFAULT 'latihan' NOT NULL,
	"waktu" time,
	"hari" varchar(50),
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "reviews" (
	"id" serial PRIMARY KEY NOT NULL,
	"session_id" integer NOT NULL,
	"member_id" integer NOT NULL,
	"rating_score" smallint NOT NULL,
	"comment" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" serial PRIMARY KEY NOT NULL,
	"title" varchar(100) NOT NULL,
	"description" text,
	"trainer_id" integer NOT NULL,
	"start_time" timestamp with time zone NOT NULL,
	"end_time" timestamp with time zone,
	"price" numeric(10, 2) DEFAULT '0.00' NOT NULL,
	"status" "session_status" DEFAULT 'scheduled' NOT NULL,
	"max_participants" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"nama" varchar(100) NOT NULL,
	"email" varchar(255) NOT NULL,
	"password" varchar(255) NOT NULL,
	"role" "user_role" DEFAULT 'customer' NOT NULL,
	"jenis_kelamin" char(1),
	"no_telp" varchar(20),
	"tanggal_lahir" date,
	"foto" varchar(255),
	"bio" text,
	"propinsi" varchar(45) DEFAULT '',
	"kota" varchar(45) DEFAULT '',
	"spesialisasi" varchar(100),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "articles" ADD CONSTRAINT "articles_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "body_progress" ADD CONSTRAINT "body_progress_member_id_users_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_member_id_users_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diet_programs" ADD CONSTRAINT "diet_programs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "progress" ADD CONSTRAINT "progress_member_id_users_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "progress" ADD CONSTRAINT "progress_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_member_id_users_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_trainer_id_users_id_fk" FOREIGN KEY ("trainer_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_articles_kategori" ON "articles" USING btree ("kategori");--> statement-breakpoint
CREATE INDEX "idx_articles_author" ON "articles" USING btree ("author_id");--> statement-breakpoint
CREATE INDEX "idx_body_progress_member" ON "body_progress" USING btree ("member_id");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_bookings_session_member" ON "bookings" USING btree ("session_id","member_id");--> statement-breakpoint
CREATE INDEX "idx_bookings_member" ON "bookings" USING btree ("member_id");--> statement-breakpoint
CREATE INDEX "idx_bookings_status" ON "bookings" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_bookings_payment_status" ON "bookings" USING btree ("payment_status");--> statement-breakpoint
CREATE INDEX "idx_diet_programs_user" ON "diet_programs" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_notifications_user" ON "notifications" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_notifications_is_read" ON "notifications" USING btree ("is_read");--> statement-breakpoint
CREATE INDEX "idx_progress_member" ON "progress" USING btree ("member_id");--> statement-breakpoint
CREATE INDEX "idx_progress_booking" ON "progress" USING btree ("booking_id");--> statement-breakpoint
CREATE INDEX "idx_reminders_user" ON "reminders" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_reviews_session" ON "reviews" USING btree ("session_id");--> statement-breakpoint
CREATE INDEX "idx_reviews_member" ON "reviews" USING btree ("member_id");--> statement-breakpoint
CREATE INDEX "idx_reviews_rating" ON "reviews" USING btree ("rating_score");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_reviews_session_member" ON "reviews" USING btree ("session_id","member_id");--> statement-breakpoint
CREATE INDEX "idx_sessions_trainer" ON "sessions" USING btree ("trainer_id");--> statement-breakpoint
CREATE INDEX "idx_sessions_start_time" ON "sessions" USING btree ("start_time");--> statement-breakpoint
CREATE INDEX "idx_sessions_trainer_start" ON "sessions" USING btree ("trainer_id","start_time");--> statement-breakpoint
CREATE INDEX "idx_users_role" ON "users" USING btree ("role");--> statement-breakpoint
CREATE INDEX "idx_users_kota" ON "users" USING btree ("kota");