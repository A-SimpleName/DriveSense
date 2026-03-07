CREATE DATABASE `drivesense` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

CREATE TABLE `account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `fname` varchar(100) NOT NULL,
  `lname` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `pwd` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `profile` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `role` varchar(50) NOT NULL,
  `account_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_user_account` (`account_id`),
  CONSTRAINT `profile_account_FK` FOREIGN KEY (`account_id`) REFERENCES `account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `profile_usergroup` (
  `profile_id` bigint NOT NULL,
  `usergroup_id` bigint NOT NULL,
  `group_role` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`usergroup_id`,`profile_id`),
  KEY `user_usergroup_user_fk` (`profile_id`),
  CONSTRAINT `profile_usergroup_profile_FK` FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`),
  CONSTRAINT `profile_usergroup_usergroup_FK` FOREIGN KEY (`usergroup_id`) REFERENCES `usergroup` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `protocol` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `profile_id` bigint NOT NULL,
  `usergroup_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `protocol_user_fk` (`profile_id`),
  CONSTRAINT `protocol_profile_FK` FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`),
  CONSTRAINT `protocol_usergroup_fk` FOREIGN KEY (`id`) REFERENCES `usergroup` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `trackingpoint` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `trip_id` bigint NOT NULL,
  `lat` decimal(10,8) NOT NULL,
  `lng` decimal(11,8) NOT NULL,
  `accuracy` decimal(6,2) DEFAULT NULL,
  `speed` decimal(6,2) DEFAULT NULL,
  `bearing` decimal(6,2) DEFAULT NULL,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_trackingpoint_tracking` (`trip_id`),
  KEY `idx_trackingpoint_timestamp` (`timestamp`),
  CONSTRAINT `trackingpoint_trip_FK` FOREIGN KEY (`trip_id`) REFERENCES `trip` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `trip` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `profile_id` bigint NOT NULL,
  `vehicle_id` bigint NOT NULL,
  `starttime` datetime NOT NULL,
  `endtime` datetime DEFAULT NULL,
  `distance` decimal(10,2) DEFAULT NULL,
  `road_surface_conditions` varchar(100) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tracking_user` (`profile_id`),
  KEY `idx_tracking_car` (`vehicle_id`),
  KEY `idx_tracking_starttime` (`starttime`),
  CONSTRAINT `trip_vehicle_FK` FOREIGN KEY (`id`) REFERENCES `vehicle` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `usergroup` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `owner_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_group_owner` (`owner_id`),
  CONSTRAINT `fk_group_owner` FOREIGN KEY (`owner_id`) REFERENCES `profile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `vehicle` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `profile_id` bigint NOT NULL,
  `model` varchar(150) NOT NULL,
  `licenseplate` varchar(20) NOT NULL,
  `mileage` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `licenseplate` (`licenseplate`),
  KEY `fk_vehicle_user` (`profile_id`),
  CONSTRAINT `fk_vehicle_user` FOREIGN KEY (`profile_id`) REFERENCES `profile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;