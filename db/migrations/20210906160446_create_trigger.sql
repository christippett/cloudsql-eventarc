-- migrate:up
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
  SELECT
    table_schema,
    table_name,
    op
  FROM
    information_schema.tables
  CROSS JOIN unnest(ARRAY['INSERT', 'UPDATE', 'DELETE']) op
WHERE
  table_type = 'BASE TABLE'
    AND table_schema NOT LIKE 'pg%'
    AND table_schema NOT IN ('meta', 'information_schema')
    LOOP
      EXECUTE format('CREATE TRIGGER %s AFTER %s ON %s FOR EACH ROW EXECUTE PROCEDURE pg2bq_notify();', r.table_name || '_notify_' || lower(r.op),
	r.op, r.table_schema || '.' || r.table_name);
    END LOOP;
END
$$;

-- migrate:down
/*
 NOTE: We rely on the previous migration's down definition to remove the triggers
 generated from the dynamic SQL above. By including the keyword `CASCADE` when
 dropping the `pg2bq_notify` function, all related objects will also be
 dropped automatically.
 */
