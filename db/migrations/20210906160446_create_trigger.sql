-- migrate:up
CREATE OR REPLACE PROCEDURE meta.create_table_event_triggers ()
LANGUAGE plpgsql
AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
  SELECT
    table_schema,
    table_name,
    op
  FROM
    information_schema.tables t
  CROSS JOIN unnest(ARRAY['INSERT', 'UPDATE', 'DELETE']) op
WHERE
  table_type = 'BASE TABLE'
    AND table_schema = 'public'
    AND NOT EXISTS (
      SELECT
        1
      FROM
        information_schema.triggers
      WHERE
        table_name = t."table_name"
        AND table_schema = 'public')
      LOOP
	EXECUTE format('CREATE TRIGGER %s AFTER %s ON %s FOR EACH ROW EXECUTE PROCEDURE meta.pg2bq_notify();', r.table_name || '_notify_' || lower(r.op),
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
