CREATE TABLE account (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    pwd VARCHAR(255) NOT NULL,
    account_id INT NOT NULL,
    group_id INT,
    FOREIGN KEY (account_id) REFERENCES account(id),
    FOREIGN KEY (group_id) REFERENCES `group`(id)
);

CREATE TABLE `group` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE car (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    model VARCHAR(100),
    consumption DECIMAL(5,2),
    licenseplate VARCHAR(20),
    mileage INT,
    FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    car_id INT NOT NULL,
    starttime DATETIME NOT NULL,
    endtime DATETIME,
    distance DECIMAL(10,2),
    weather_main VARCHAR(50),
    weather_description VARCHAR(100),
    type VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES user(id),
    FOREIGN KEY (car_id) REFERENCES car(id)
);

CREATE TABLE trackingpoint (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_id INT NOT NULL,
    lat DECIMAL(9,6) NOT NULL,
    lng DECIMAL(9,6) NOT NULL,
    accuracy DECIMAL(5,2),
    speed DECIMAL(5,2),
    bearing DECIMAL(5,2),
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (tracking_id) REFERENCES tracking(id)
);

CREATE TABLE protocol (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_id INT NOT NULL UNIQUE,
    road_surface_conditions VARCHAR(100),
    weather_raw TEXT,
    FOREIGN KEY (tracking_id) REFERENCES tracking(id)
);

CREATE TABLE protocol_user (
    protocol_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(50) NOT NULL,
    PRIMARY KEY (protocol_id, user_id),
    FOREIGN KEY (protocol_id) REFERENCES protocol(id),
    FOREIGN KEY (user_id) REFERENCES user(id)
);

