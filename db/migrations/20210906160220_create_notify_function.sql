-- migrate:up
CREATE OR REPLACE FUNCTION pg2bq_notify ()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  rec RECORD;
BEGIN
  IF TG_OP = 'DELETE' THEN
    rec = OLD;
  ELSE
    rec = NEW;
  END IF;
  PERFORM
    pg_notify('pg2bq', json_build_object('table', TG_TABLE_NAME,
      'type', TG_OP, 'row', row_to_json(rec), 'timestamp',
      extract(epoch FROM now())));
  RETURN NEW;
END
$$;

-- migrate:down
DROP FUNCTION IF EXISTS pg2bq_notify CASCADE;
