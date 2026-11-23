-- Таблица показаний датчиков (TEMP-01, HUM-01)
CREATE TABLE measurements (
    id          INTEGER PRIMARY KEY,
    source      TEXT NOT NULL,
    device_id   TEXT NOT NULL,
    metric      TEXT NOT NULL,
    zone        TEXT NOT NULL,
    timestamp   INTEGER NOT NULL,
    received_at INTEGER NOT NULL,
    value       REAL NOT NULL,
    unit        TEXT NOT NULL,
    labels      TEXT NOT NULL DEFAULT '{}'
);

-- Таблица событий исполнительного устройства (FAN-01)
CREATE TABLE actuator_events (
    id          INTEGER PRIMARY KEY,
    source      TEXT NOT NULL,
    device_id   TEXT NOT NULL,
    zone        TEXT NOT NULL,
    timestamp   INTEGER NOT NULL,
    received_at INTEGER NOT NULL,
    state       TEXT NOT NULL,
    mode        TEXT NOT NULL
);
