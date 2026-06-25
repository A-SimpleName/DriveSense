ALTER TABLE `trip`
  ADD COLUMN `road_snap_status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  ADD COLUMN `road_snap_attempts` INT NOT NULL DEFAULT 0,
  ADD COLUMN `road_snap_last_error` VARCHAR(500) DEFAULT NULL,
  ADD COLUMN `road_snap_next_retry_at` DATETIME DEFAULT NULL,
  ADD COLUMN `road_snap_updated_at` DATETIME DEFAULT NULL;

ALTER TABLE `trackingpoint`
  ADD COLUMN `point_source` VARCHAR(20) NOT NULL DEFAULT 'RAW';
