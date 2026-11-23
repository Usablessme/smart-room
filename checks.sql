-- Последние 10 показаний датчиков
SELECT id, device_id, metric, value, unit, timestamp, received_at
FROM measurements
ORDER BY id DESC
LIMIT 10;

-- Последние 10 событий вентилятора
SELECT id, device_id, state, mode, timestamp, received_at
FROM actuator_events
ORDER BY id DESC
LIMIT 10;

-- Сколько записей у каждого устройства (показания)
SELECT device_id, COUNT(*) AS rows_count
FROM measurements
GROUP BY device_id;

-- Сколько записей у вентилятора по состояниям
SELECT device_id, state, COUNT(*) AS rows_count
FROM actuator_events
GROUP BY device_id, state;
