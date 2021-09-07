-- migrate:up
CREATE OR REPLACE PROCEDURE meta.tag_event (id integer, status meta.job_status_type)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE
    meta.table_events tbl
  SET
    tbl.updated = (now() AT TIME ZONE 'utc')
  WHERE
    tbl.id = id;
END
$$;

-- migrate:down
DROP PROCEDURE IF EXISTS meta.tag_event;
