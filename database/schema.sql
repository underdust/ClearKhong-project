DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='post_status') THEN
    CREATE TYPE post_status AS ENUM ('draft','pending','approved','rejected','closed');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role VARCHAR(10) NOT NULL DEFAULT 'user',
  shop_name VARCHAR(50),
  phone VARCHAR(10),
  email VARCHAR(50),
  profile_image_url TEXT,
  tokens INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(12,2),
  is_sell BOOLEAN NOT NULL DEFAULT FALSE,
  is_trade BOOLEAN NOT NULL DEFAULT FALSE,
  tags TEXT[] NOT NULL DEFAULT '{}',
  image_url TEXT,
  status post_status NOT NULL DEFAULT 'pending',
  promoted BOOLEAN NOT NULL DEFAULT FALSE,
  promoted_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchases (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  buyer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trades (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  proposer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  description TEXT,
  image_url TEXT,
  status VARCHAR(12) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS comments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  read BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS reports (
  id SERIAL PRIMARY KEY,
  reporter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reasons TEXT,
  details TEXT,
  images TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE reports ADD COLUMN IF NOT EXISTS details    TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS images     TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS status     VARCHAR(20) NOT NULL DEFAULT 'open';
ALTER TABLE reports ADD COLUMN IF NOT EXISTS created_at TIMESTAMP  NOT NULL DEFAULT NOW();
ALTER TABLE reports ADD COLUMN IF NOT EXISTS reasons    TEXT;
UPDATE reports SET reasons = '' WHERE reasons IS NULL;
ALTER TABLE reports ALTER COLUMN reasons SET DEFAULT '';

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_status_check;
ALTER TABLE reports ADD CONSTRAINT reports_status_check 
  CHECK (status IN ('open','reviewing','resolved'));

ALTER TABLE reports ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE reports ALTER COLUMN type SET DEFAULT 'user';
UPDATE reports SET type = 'user' WHERE type IS NULL;
ALTER TABLE reports ALTER COLUMN type SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'post_status' AND e.enumlabel = 'waiting'
  ) THEN
    ALTER TYPE post_status ADD VALUE 'waiting';
  END IF;
END $$;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS bio     TEXT;

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS approved_by     INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejected_by     INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS rejected_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejected_reason TEXT;

ALTER TABLE IF EXISTS public.notifications
  ADD COLUMN IF NOT EXISTS post_id  INTEGER,
  ADD COLUMN IF NOT EXISTS actor_id INTEGER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_indexes
    WHERE  schemaname = 'public'
      AND  indexname  = 'uniq_posts_user_title'
  ) THEN
    CREATE UNIQUE INDEX uniq_posts_user_title ON public.posts(user_id, title);
  END IF;
END $$;

-- Safe migration for existing databases
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='posts' AND column_name='promoted_at'
  ) THEN
    ALTER TABLE posts ADD COLUMN promoted_at TIMESTAMP NULL;
  END IF;
  -- Backfill for already-promoted posts without timestamp
  UPDATE posts SET promoted_at = NOW()
  WHERE promoted = TRUE AND promoted_at IS NULL;
  -- Index to speed up ordering by promoted_at
  CREATE INDEX IF NOT EXISTS idx_posts_promoted_at_desc ON posts (promoted_at DESC NULLS LAST);
END $$;

-- Enforce positive price if provided
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_posts_price_positive'
  ) THEN
    ALTER TABLE posts
    ADD CONSTRAINT chk_posts_price_positive
    CHECK (price IS NULL OR price > 0);
  END IF;
END $$;
