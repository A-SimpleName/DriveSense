-- =====================================================
-- DriveSense Database Schema
-- =====================================================

-- -----------------------------------------------------
-- ACCOUNT
-- -----------------------------------------------------
CREATE TABLE account (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    fname           VARCHAR(100) NOT NULL,
    lname           VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    pwd             VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- USER
-- -----------------------------------------------------
CREATE TABLE user (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    role            VARCHAR(50) NOT NULL,
    account_id      BIGINT NOT NULL,
    group_id        BIGINT NULL,
    
    CONSTRAINT fk_user_account
        FOREIGN KEY (account_id)
        REFERENCES account(id)
        ON DELETE CASCADE
);

-- -----------------------------------------------------
-- GROUP
-- -----------------------------------------------------
CREATE TABLE user_group (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    owner_id    BIGINT NOT NULL,
    
    CONSTRAINT fk_group_owner
        FOREIGN KEY (owner_id)
        REFERENCES user(id)
        ON DELETE CASCADE
);

-- Jetzt GROUP_ID als FK ergänzen (wegen Reihenfolge)
ALTER TABLE user
ADD CONSTRAINT fk_user_group
FOREIGN KEY (group_id)
REFERENCES user_group(id)
ON DELETE SET NULL;

-- -----------------------------------------------------
-- VEHICLE
-- -----------------------------------------------------
CREATE TABLE vehicle (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    model           VARCHAR(150) NOT NULL,
    licenseplate    VARCHAR(20) NOT NULL UNIQUE,
    mileage         INT DEFAULT 0,
    
    CONSTRAINT fk_vehicle_user
        FOREIGN KEY (user_id)
        REFERENCES user(id)
        ON DELETE CASCADE
);

-- -----------------------------------------------------
-- TRACKING
-- -----------------------------------------------------
CREATE TABLE tracking (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    car_id              BIGINT NOT NULL,
    starttime           DATETIME NOT NULL,
    endtime             DATETIME,
    distance            DECIMAL(10,2),
    weather_main        VARCHAR(100),
    type                VARCHAR(50),
    
    CONSTRAINT fk_tracking_user
        FOREIGN KEY (user_id)
        REFERENCES user(id)
        ON DELETE CASCADE,
        
    CONSTRAINT fk_tracking_vehicle
        FOREIGN KEY (car_id)
        REFERENCES vehicle(id)
        ON DELETE CASCADE
);

-- Index für häufige Abfragen
CREATE INDEX idx_tracking_user ON tracking(user_id);
CREATE INDEX idx_tracking_car ON tracking(car_id);
CREATE INDEX idx_tracking_starttime ON tracking(starttime);

-- -----------------------------------------------------
-- TRACKINGPOINT
-- -----------------------------------------------------
CREATE TABLE trackingpoint (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    tracking_id     BIGINT NOT NULL,
    lat             DECIMAL(10,8) NOT NULL,
    lng             DECIMAL(11,8) NOT NULL,
    accuracy        DECIMAL(6,2),
    speed           DECIMAL(6,2),
    bearing         DECIMAL(6,2),
    timestamp       DATETIME NOT NULL,
    
    CONSTRAINT fk_trackingpoint_tracking
        FOREIGN KEY (tracking_id)
        REFERENCES tracking(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_trackingpoint_tracking ON trackingpoint(tracking_id);
CREATE INDEX idx_trackingpoint_timestamp ON trackingpoint(timestamp);

-- -----------------------------------------------------
-- PROTOCOL (1:1 mit TRACKING)
-- -----------------------------------------------------
CREATE TABLE protocol (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    tracking_id             BIGINT NOT NULL UNIQUE,
    road_surface_conditions VARCHAR(255),
    
    CONSTRAINT fk_protocol_tracking
        FOREIGN KEY (tracking_id)
        REFERENCES tracking(id)
        ON DELETE CASCADE
);

-- -----------------------------------------------------
-- PROTOCOL_USER (n:m Beziehung)
-- -----------------------------------------------------
CREATE TABLE protocol_user (
    protocol_id     BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    user_role       VARCHAR(50),
    
    PRIMARY KEY (protocol_id, user_id),
    
    CONSTRAINT fk_protocoluser_protocol
        FOREIGN KEY (protocol_id)
        REFERENCES protocol(id)
        ON DELETE CASCADE,
        
    CONSTRAINT fk_protocoluser_user
        FOREIGN KEY (user_id)
        REFERENCES user(id)
        ON DELETE CASCADE
);

-- Index für Performance
CREATE INDEX idx_protocoluser_user ON protocol_user(user_id);

-- =====================================================
-- Ende Schema
-- =====================================================