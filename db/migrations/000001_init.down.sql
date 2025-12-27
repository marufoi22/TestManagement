-- 1) enums
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('tester', 'se', 'programmer');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE release_status AS ENUM ('planning', 'in_progress', 'done');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE test_case_status AS ENUM (
    'not_started', 'in_progress', 'pass', 'fail', 'blocked', 'on_hold', 'na'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE test_run_result AS ENUM ('pass', 'fail', 'blocked', 'on_hold');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE priority_level AS ENUM ('high', 'medium', 'low');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2) users
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  role user_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3) releases
CREATE TABLE IF NOT EXISTS releases (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  start_date DATE,
  end_date DATE,
  status release_status NOT NULL DEFAULT 'planning',
  created_by BIGINT REFERENCES users(id),
  updated_by BIGINT REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4) test_cases
CREATE TABLE IF NOT EXISTS test_cases (
  id BIGSERIAL PRIMARY KEY,
  release_id BIGINT NOT NULL REFERENCES releases(id) ON DELETE CASCADE,

  screen_name TEXT NOT NULL,
  screen_path TEXT,
  check_points TEXT,
  expected_result TEXT,

  status test_case_status NOT NULL DEFAULT 'not_started',
  priority priority_level NOT NULL DEFAULT 'medium',
  assignee_user_id BIGINT REFERENCES users(id),

  last_result test_run_result,
  last_executed_at TIMESTAMPTZ,

  created_by BIGINT REFERENCES users(id),
  updated_by BIGINT REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5) test_runs (履歴)
CREATE TABLE IF NOT EXISTS test_runs (
  id BIGSERIAL PRIMARY KEY,
  test_case_id BIGINT NOT NULL REFERENCES test_cases(id) ON DELETE CASCADE,

  result test_run_result NOT NULL,
  comment TEXT,
  evidence_url TEXT,

  executed_by_user_id BIGINT REFERENCES users(id),
  executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6) indexes
CREATE INDEX IF NOT EXISTS idx_test_cases_release_status
  ON test_cases (release_id, status);

CREATE INDEX IF NOT EXISTS idx_test_cases_release_assignee
  ON test_cases (release_id, assignee_user_id);

CREATE INDEX IF NOT EXISTS idx_test_runs_case_time
  ON test_runs (test_case_id, executed_at DESC);

-- 7) simple constraints (MVP)
-- Fail/Blocked/OnHold のときコメント必須はアプリ側で必須化がおすすめ
-- DBでもやるなら CHECK/trigger で可能（後で追加でもOK）
