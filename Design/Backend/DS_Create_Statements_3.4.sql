CREATE TABLE `account` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `fname` VARCHAR(100) NOT NULL,
  `lname` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `pwd` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `birthdate` DATE DEFAULT NULL,
  `email_verified` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_account_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `profile` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `role` VARCHAR(50) NOT NULL,
  `account_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_profile_account_name_role` (`account_id`,`name`,`role`),
  CONSTRAINT `fk_profile_account`
    FOREIGN KEY (`account_id`) REFERENCES `account` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `usergroup` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `owner_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_group_owner`
    FOREIGN KEY (`owner_id`) REFERENCES `profile` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `vehicle` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `model` VARCHAR(150) NOT NULL,
  `licenseplate` VARCHAR(20) NOT NULL,
  `mileage` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vehicle_licenseplate` (`licenseplate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `profile_vehicle` (
  `profile_id` BIGINT NOT NULL,
  `vehicle_id` BIGINT NOT NULL,
  `role` VARCHAR(20) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`vehicle_id`, `profile_id`),

  CONSTRAINT `fk_pv_profile`
    FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_pv_vehicle`
    FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle` (`id`)
    ON DELETE CASCADE,

  CONSTRAINT `chk_pv_role`
    CHECK (`role` IN ('OWNER','CO_OWNER','DRIVER'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `protocol` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `created_by_profile_id` BIGINT NOT NULL,
  `usergroup_id` BIGINT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),

  CONSTRAINT `fk_protocol_profile`
    FOREIGN KEY (`created_by_profile_id`) REFERENCES `profile` (`id`),

  CONSTRAINT `fk_protocol_group`
    FOREIGN KEY (`usergroup_id`) REFERENCES `usergroup` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trip` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `profile_id` BIGINT NOT NULL,
  `vehicle_id` BIGINT NOT NULL,
  `starttime` DATETIME NOT NULL,
  `endtime` DATETIME DEFAULT NULL,
  `distance` DECIMAL(10,2),
  `road_surface_conditions` VARCHAR(100),
  `type` VARCHAR(50),
  `protocol_id` BIGINT,
  `start_point` VARCHAR(100) NOT NULL,
  `end_point` VARCHAR(100) NOT NULL,
  `furthest_point` VARCHAR(100) NOT NULL,
  `start_mileage` INT NOT NULL,
  `end_mileage` INT NOT NULL,
  PRIMARY KEY (`id`),

  CONSTRAINT `fk_trip_profile`
    FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`),

  CONSTRAINT `fk_trip_vehicle`
    FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle` (`id`),

  CONSTRAINT `fk_trip_protocol`
    FOREIGN KEY (`protocol_id`) REFERENCES `protocol` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trackingpoint` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `trip_id` BIGINT NOT NULL,
  `lat` DECIMAL(10,8) NOT NULL,
  `lng` DECIMAL(11,8) NOT NULL,
  `accuracy` DECIMAL(6,2),
  `speed` DECIMAL(6,2),
  `bearing` DECIMAL(6,2),
  `timestamp` DATETIME NOT NULL,
  PRIMARY KEY (`id`),

  CONSTRAINT `fk_tp_trip`
    FOREIGN KEY (`trip_id`) REFERENCES `trip` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `profile_usergroup` (
  `profile_id` BIGINT NOT NULL,
  `usergroup_id` BIGINT NOT NULL,
  `group_role` VARCHAR(20) NOT NULL DEFAULT 'MEMBER',

  PRIMARY KEY (`usergroup_id`, `profile_id`),

  CONSTRAINT `fk_pug_profile`
    FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`),

  CONSTRAINT `fk_pug_group`
    FOREIGN KEY (`usergroup_id`) REFERENCES `usergroup` (`id`),

  CONSTRAINT `chk_pug_role`
    CHECK (`group_role` IN ('OWNER','ADMIN','MEMBER'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Gruppeneinladung
CREATE TABLE `group_invitation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT NOT NULL,
  `invited_account_id` BIGINT NOT NULL,
  `invited_by_profile_id` BIGINT NOT NULL,
  `code_hash` VARCHAR(255) NOT NULL,
  `status` ENUM('PENDING','ACCEPTED','EXPIRED') NOT NULL DEFAULT 'PENDING',
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_gi_group`
    FOREIGN KEY (`group_id`) REFERENCES `usergroup` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_gi_invited_account`
    FOREIGN KEY (`invited_account_id`) REFERENCES `account` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_gi_invited_by`
    FOREIGN KEY (`invited_by_profile_id`) REFERENCES `profile` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Passwort vergessen
CREATE TABLE `password_reset_token` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `account_id` BIGINT NOT NULL,
  `code_hash` VARCHAR(255) NOT NULL,
  `used` BOOLEAN NOT NULL DEFAULT FALSE,
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_prt_account`
    FOREIGN KEY (`account_id`) REFERENCES `account` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Email Verifizierung
CREATE TABLE `email_verification` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `account_id` BIGINT NOT NULL,
  `code_hash` VARCHAR(255) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ev_account`
    FOREIGN KEY (`account_id`) REFERENCES `account` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;