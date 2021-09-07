-- migrate:up
CREATE TYPE meta.job_status_type AS ENUM (
  'new',
  'processing',
  'done'
);

CREATE TABLE IF NOT EXISTS meta.table_events (
  id serial PRIMARY KEY,
  op varchar(20) NOT NULL,
  table_schema varchar(20) NOT NULL,
  table_name varchar NOT NULL,
  data jsonb NULL,
  status meta.job_status_type NOT NULL DEFAULT 'new',
  created timestamp without time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  updated timestamp without time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

-- migrate:down
DROP TABLE IF EXISTS meta.table_events;

DROP TYPE IF EXISTS meta.job_status_type CASCADE;
