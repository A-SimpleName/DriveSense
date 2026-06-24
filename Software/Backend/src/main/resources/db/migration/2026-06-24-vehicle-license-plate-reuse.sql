-- Allows a deleted vehicle's license plate to be reused.
-- MySQL UNIQUE indexes allow multiple NULL values, so keeping the existing
-- UNIQUE(license_plate) constraint is fine once deleted rows have license_plate = NULL.
ALTER TABLE vehicle
    MODIFY license_plate VARCHAR(20) NULL;

UPDATE vehicle
SET license_plate = NULL
WHERE deleted_at IS NOT NULL;
