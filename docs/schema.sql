-- ============================================================
-- myleads.db  —  SQLite schema v9
-- Generated from lib/services/database_service.dart
-- ============================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ============================================================
-- USERS
-- Sensitive PII columns are AES-256-CBC encrypted (_enc suffix).
-- Lookup columns store deterministic SHA-256 hashes for
-- uniqueness queries without decrypting the ciphertext.
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id                   TEXT PRIMARY KEY,
  email_enc            TEXT NOT NULL,
  email_lookup         TEXT NOT NULL UNIQUE,       -- SHA-256(salt::normalizedEmail)
  first_name_enc       TEXT NOT NULL,
  last_name_enc        TEXT NOT NULL,
  nickname_enc         TEXT,
  phone_enc            TEXT,
  phone_lookup         TEXT UNIQUE,                -- SHA-256(salt::normalizedPhone)
  date_of_birth_enc    TEXT,                       -- kept for schema compat; no longer written (doc v7)
  company_name_enc     TEXT,
  company_role_enc     TEXT,
  biography_enc        TEXT,
  password_hash        TEXT NOT NULL,              -- SHA-256 with salt
  auth_provider        TEXT NOT NULL DEFAULT 'email',
  session_token        TEXT,
  created_at           TEXT NOT NULL,              -- ISO-8601
  last_login_at        TEXT,                       -- ISO-8601
  password_changed_at  TEXT NOT NULL,              -- ISO-8601; rotated on password change
  photo_path           TEXT,
  email_verified       INTEGER NOT NULL DEFAULT 0, -- 0=false, 1=true
  organization_id      TEXT,                       -- FK → organizations.id (nullable)
  org_role             TEXT,                       -- 'admin' | 'member' | NULL
  plan                 TEXT NOT NULL DEFAULT 'free' -- 'free' | 'premium' | 'business'
);

-- ============================================================
-- CONTACTS
-- phone and email are stored as plaintext in the app model but
-- _lookup columns hold SHA-256 hashes for duplicate detection.
-- ============================================================
CREATE TABLE IF NOT EXISTS contacts (
  id                TEXT PRIMARY KEY,
  owner_id          TEXT NOT NULL,
  first_name        TEXT NOT NULL,
  last_name         TEXT NOT NULL,
  job_title         TEXT,
  company           TEXT,
  phone             TEXT,
  email             TEXT,
  phone_lookup      TEXT,                         -- SHA-256(salt::normalizedPhone)
  email_lookup      TEXT,                         -- SHA-256(salt::normalizedEmail)
  source            TEXT,
  project_1         TEXT,
  project_1_budget  TEXT,
  project_2         TEXT,
  project_2_budget  TEXT,
  interest          TEXT,
  notes             TEXT,
  tags              TEXT,                         -- JSON array e.g. '["vip","client"]'
  status            TEXT NOT NULL DEFAULT 'warm', -- 'hot' | 'warm' | 'cold'
  created_at        TEXT NOT NULL,                -- ISO-8601
  last_contact_date TEXT,                         -- ISO-8601
  avatar_color      TEXT,
  capture_method    TEXT NOT NULL DEFAULT 'manual', -- 'manual'|'scan'|'qr'|'nfc'
  photo_path        TEXT,
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_contacts_owner
  ON contacts(owner_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_owner_phone
  ON contacts(owner_id, phone_lookup)
  WHERE phone_lookup IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_owner_email
  ON contacts(owner_id, email_lookup)
  WHERE email_lookup IS NOT NULL;

-- ============================================================
-- REMINDERS  (v5 schema: multi-contact + scheduling)
-- contact_ids is a JSON array; contact_id mirrors the first
-- element for backwards-compat with pre-v5 rows.
-- priority_v2 is the canonical priority; the legacy priority
-- column is kept for migration safety only.
-- ============================================================
CREATE TABLE IF NOT EXISTS reminders (
  id               TEXT PRIMARY KEY,
  owner_id         TEXT NOT NULL,
  contact_id       TEXT,                             -- legacy: first element of contact_ids
  contact_ids      TEXT NOT NULL DEFAULT '[]',       -- JSON array of contact IDs
  start_date_time  TEXT NOT NULL,                    -- ISO-8601
  end_date_time    TEXT,                             -- ISO-8601; NULL = no end
  repeat_frequency TEXT,                             -- e.g. 'daily' | 'weekly' | NULL
  note             TEXT NOT NULL DEFAULT '',
  todo_action      TEXT NOT NULL DEFAULT 'call',     -- 'call'|'sms'|'whatsapp'|'email'
  priority_v2      TEXT NOT NULL DEFAULT 'normal',   -- 'very_important'|'important'|'normal'
  -- legacy columns (kept for migration compat, not read by the app)
  title            TEXT,
  description      TEXT,
  due_date         TEXT,
  priority         TEXT,                             -- 'urgent'|'soon'|'later'
  is_completed     INTEGER NOT NULL DEFAULT 0,       -- 0=false, 1=true
  created_at       TEXT NOT NULL                     -- ISO-8601
);

CREATE INDEX IF NOT EXISTS idx_reminders_owner
  ON reminders(owner_id);

-- ============================================================
-- INTERACTIONS
-- Audit log for contact actions (call, sms, whatsapp, email,
-- note) and field-level edits (type='edit').
-- ============================================================
CREATE TABLE IF NOT EXISTS interactions (
  id          TEXT PRIMARY KEY,
  owner_id    TEXT NOT NULL,
  contact_id  TEXT NOT NULL,
  type        TEXT NOT NULL,   -- 'call'|'sms'|'whatsapp'|'email'|'note'|'edit'
  content     TEXT NOT NULL,
  created_at  TEXT NOT NULL,   -- ISO-8601
  FOREIGN KEY (owner_id)   REFERENCES users(id)    ON DELETE CASCADE,
  FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_interactions_contact
  ON interactions(contact_id);

-- ============================================================
-- PAYMENT METHODS
-- Full card / payment details are AES-256 encrypted in
-- encrypted_details.
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id                 TEXT PRIMARY KEY,
  owner_id           TEXT NOT NULL,
  type               TEXT NOT NULL,   -- 'card' | 'sepa' | …
  label              TEXT NOT NULL,
  encrypted_details  TEXT NOT NULL,
  created_at         TEXT NOT NULL,   -- ISO-8601
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- SESSION  (single-row key/value store for the active session)
-- ============================================================
CREATE TABLE IF NOT EXISTS session (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);

-- ============================================================
-- NOTIFICATIONS  (v6)
-- In-app notification inbox. reference_id points to the related
-- entity (contact, reminder) when applicable.
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id            TEXT PRIMARY KEY,
  owner_id      TEXT NOT NULL,
  type          TEXT NOT NULL,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  scheduled_at  TEXT NOT NULL,  -- ISO-8601
  created_at    TEXT NOT NULL,  -- ISO-8601
  reference_id  TEXT,
  is_read       INTEGER NOT NULL DEFAULT 0  -- 0=false, 1=true
);

CREATE INDEX IF NOT EXISTS idx_notifications_owner
  ON notifications(owner_id);

-- ============================================================
-- ORGANIZATIONS  (v7)
-- invite_code is the 6-char uppercase join code shown in the UI.
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  owner_id     TEXT NOT NULL,              -- FK → users.id (not enforced to allow delete order flexibility)
  invite_code  TEXT NOT NULL UNIQUE,
  created_at   TEXT NOT NULL              -- ISO-8601
);

-- ============================================================
-- ORGANIZATION MEMBERS  (v7 + v8 privileges)
-- can_edit  / can_create are per-member flags; admins always
-- get both regardless of the stored value.
-- ============================================================
CREATE TABLE IF NOT EXISTS organization_members (
  id               TEXT PRIMARY KEY,
  organization_id  TEXT NOT NULL,
  user_id          TEXT NOT NULL,
  role             TEXT NOT NULL DEFAULT 'member',  -- 'admin' | 'member'
  status           TEXT NOT NULL DEFAULT 'active',  -- 'active' | 'inactive'
  joined_at        TEXT NOT NULL,                   -- ISO-8601
  can_edit         INTEGER NOT NULL DEFAULT 0,      -- 0=false, 1=true (overridden by role='admin')
  can_create       INTEGER NOT NULL DEFAULT 1,      -- 0=false, 1=true (overridden by role='admin')
  FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)         REFERENCES users(id)         ON DELETE CASCADE,
  UNIQUE (organization_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_org_members_org
  ON organization_members(organization_id);

CREATE INDEX IF NOT EXISTS idx_org_members_user
  ON organization_members(user_id);
