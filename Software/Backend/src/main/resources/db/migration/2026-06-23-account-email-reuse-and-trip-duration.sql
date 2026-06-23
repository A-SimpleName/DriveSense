-- Allows a deleted account's email address to be reused.
-- MySQL UNIQUE indexes allow multiple NULL values, so keeping the existing
-- UNIQUE(email) constraint is fine once deleted rows have email = NULL.
ALTER TABLE account
    MODIFY email VARCHAR(255) NULL;

UPDATE account
SET email = NULL,
    pending_email = NULL
WHERE deleted_at IS NOT NULL;

-- Stores active driving time in seconds. This must exclude paused time.
ALTER TABLE trip
    ADD COLUMN duration_seconds BIGINT NOT NULL DEFAULT 0 AFTER distance;

UPDATE trip
SET duration_seconds = GREATEST(TIMESTAMPDIFF(SECOND, start_time, end_time), 0)
WHERE duration_seconds = 0
  AND start_time IS NOT NULL
  AND end_time IS NOT NULL;
