-- Oyuntan Platform - PostgreSQL Schema
-- psql -U postgres -d oyuntan -f schema.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Users (нийтлэг) ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  uid           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  type          VARCHAR(20)  NOT NULL CHECK (type IN ('student', 'company')),
  language      VARCHAR(10)  DEFAULT 'mn',
  created_at    TIMESTAMP    DEFAULT NOW()
);

-- ── Оюутан ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  uid         UUID PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  first_name  VARCHAR(100),
  last_name   VARCHAR(100),
  university  VARCHAR(255),
  major       VARCHAR(255),
  year        INTEGER,
  skills      TEXT[],
  bio         TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMP DEFAULT NOW()
);

-- ── Компани ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
  uid          UUID PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  name         VARCHAR(255),
  industry     VARCHAR(255),
  description  TEXT,
  location     VARCHAR(255),
  website      VARCHAR(255),
  logo_url     TEXT,
  avg_score    DECIMAL(3,1) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  created_at   TIMESTAMP DEFAULT NOW()
);

-- ── Дадлагын зар ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS internship_posts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       UUID REFERENCES users(uid),
  title            VARCHAR(255),
  description      TEXT,
  location         VARCHAR(255),
  duration_days    INTEGER,
  required_skills  TEXT[],
  salary           DECIMAL,
  is_active        BOOLEAN DEFAULT TRUE,
  applicant_count  INTEGER DEFAULT 0,
  created_at       TIMESTAMP DEFAULT NOW()
);

-- ── Өргөдөл ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS applications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     UUID REFERENCES internship_posts(id),
  student_id  UUID REFERENCES users(uid),
  company_id  UUID REFERENCES users(uid),
  status      VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  message     TEXT,
  created_at  TIMESTAMP DEFAULT NOW(),
  UNIQUE(post_id, student_id)
);

-- ── Дадлага ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS internships (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id          UUID REFERENCES users(uid),
  post_id             UUID REFERENCES internship_posts(id),
  company_id          UUID REFERENCES users(uid),
  status              VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'terminated')),
  duration_days       INTEGER,
  start_date          TIMESTAMP DEFAULT NOW(),
  end_date            TIMESTAMP,
  completed_days      INTEGER DEFAULT 0,
  terminated_by       VARCHAR(20),   -- 'student' | 'company'
  termination_reason  TEXT
);

-- Migration (existing DB): run these once
-- ALTER TABLE internships ADD COLUMN IF NOT EXISTS terminated_by VARCHAR(20);
-- ALTER TABLE internships ADD COLUMN IF NOT EXISTS termination_reason TEXT;
-- ALTER TABLE internships DROP CONSTRAINT IF EXISTS internships_status_check;
-- ALTER TABLE internships ADD CONSTRAINT internships_status_check CHECK (status IN ('active','completed','terminated'));
-- ALTER TABLE students ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
-- ALTER TABLE students ADD COLUMN IF NOT EXISTS psych_profile JSONB;

-- ── Хичээлийн хуваарь ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS class_schedules (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID REFERENCES users(uid) ON DELETE CASCADE,
  day         SMALLINT NOT NULL CHECK (day BETWEEN 0 AND 6),
  subject     VARCHAR(255) NOT NULL,
  start_hour  SMALLINT NOT NULL,
  start_min   SMALLINT NOT NULL DEFAULT 0,
  end_hour    SMALLINT NOT NULL,
  end_min     SMALLINT NOT NULL DEFAULT 0,
  room        VARCHAR(100),
  teacher     VARCHAR(255),
  type        VARCHAR(50) DEFAULT 'Лекц'
);

-- ── Өдрийн тэмдэглэл ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS diary_entries (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  internship_id  UUID REFERENCES internships(id),
  student_id     UUID REFERENCES users(uid),
  day_number     INTEGER,
  work_done      TEXT,
  mood           VARCHAR(50),
  interactions   TEXT,
  categories     TEXT[],
  date           TIMESTAMP DEFAULT NOW(),
  UNIQUE(internship_id, day_number)
);

-- ── Үнэлгээ ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  internship_id  UUID UNIQUE REFERENCES internships(id),
  student_id     UUID REFERENCES users(uid),
  company_id     UUID REFERENCES users(uid),
  env_score      INTEGER CHECK (env_score BETWEEN 1 AND 5),
  mentor_score   INTEGER CHECK (mentor_score BETWEEN 1 AND 5),
  learn_score    INTEGER CHECK (learn_score BETWEEN 1 AND 5),
  relation_score INTEGER CHECK (relation_score BETWEEN 1 AND 5),
  avg_score      DECIMAL(3,1),
  would_return   BOOLEAN,
  comment        TEXT,
  created_at     TIMESTAMP DEFAULT NOW()
);

-- ── Компанийн оюутанд өгсөн үнэлгээ ────────────────────────────
CREATE TABLE IF NOT EXISTS student_reviews (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  internship_id     UUID UNIQUE REFERENCES internships(id),
  company_id        UUID REFERENCES users(uid),
  student_id        UUID REFERENCES users(uid),
  work_score        INTEGER CHECK (work_score BETWEEN 1 AND 5),
  attitude_score    INTEGER CHECK (attitude_score BETWEEN 1 AND 5),
  punctuality_score INTEGER CHECK (punctuality_score BETWEEN 1 AND 5),
  learning_score    INTEGER CHECK (learning_score BETWEEN 1 AND 5),
  avg_score         DECIMAL(3,1),
  would_rehire      BOOLEAN,
  comment           TEXT,
  created_at        TIMESTAMP DEFAULT NOW()
);

-- ── CV ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cvs (
  student_id  UUID PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  data        JSONB,
  updated_at  TIMESTAMP DEFAULT NOW()
);

-- ── Мэдэгдэл ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  to_uid      UUID REFERENCES users(uid),
  type        VARCHAR(50),
  post_id     UUID,
  student_id  UUID,
  read        BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT NOW()
);
