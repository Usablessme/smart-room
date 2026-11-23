# Журнал работ и испытаний стенда LAB-01

Даты проведения: 23-24.11.2026. Скриншоты лежат в `docs/screens/`.

## Ход работ

| № | Работа | Результат |
|---|---|---|
| 1 | ВМ LAB-01 (РЕД ОС 8.0.3), Docker, Compose, Git, sqlite3 | `docker compose version` = 5.3.1, `sqlite3 --version` = 3.40.0 |
| 2 | `compose.yml` с сервисами nodered, ctrl, storage | `docker compose config` без ошибок |
| 3 | SQLite создана вручную по `schema.sql` | `.tables`, `.schema`, `PRAGMA quick_check` = ok; storage запустился |
| 4 | Потоки Node-RED (TEMP, HUM, FAN) | `iot/flows.json`, ответы 200 от CTRL и storage |
| 5 | Prometheus и Grafana как системные службы | цель office-controller UP, панель и правило созданы |

## Испытания

### 1. Штатный режим
- **Ожидание:** TEMP и HUM поступают раз в 5 секунд; новые строки обоих датчиков и FAN есть в SQLite.
- **Факт:** метки времени в `measurements` идут шагом около 5000 мс; в базе есть TEMP-01, HUM-01 и FAN-01; Debug показывает 200 от CTRL и storage.
- **Время:** 23.11.2026, 00:57 (история, 147 записей) и далее `checks.sql`.
- **Скриншоты:** ![debug](screens/01-nodered-debug-200.png) ![история](screens/02-history-rows.png) ![checks](screens/03-checks-sql.png)

### 2. Порог FAN
| Температура | Ожидание | Факт | Время | Скриншот |
|---|---|---|---|---|
| 29 °C | OFF | OFF | 23.11, 02:08:24 | ![29](screens/04-fan-29-off.png) |
| 30 °C | ON | ON | 23.11, 02:08:43 | ![30](screens/05-fan-30-on.png) |
| 31 °C | ON | ON | 23.11, 02:09:18 | ![31](screens/06-fan-31-on-history.png) |
| 29 °C (возврат) | OFF | OFF | 24.11, 01:05:55 | ![29 назад](screens/07-fan-29-return-off.png) |

Состояние видно в CTRL (`office_fan_on`), в SQLite (`actuator_events`), в Grafana и на странице истории.

### 3. Изменение значения
- **Ожидание:** новое значение после Deploy видно в следующей отправке, истории и Grafana с учётом периодов обновления.
- **Факт:** значение 35 °C после Deploy появилось в CTRL (`office_temperature_celsius` = 35, `office_fan_on` = 1), в SQLite (FAN-01 ON) и в Grafana (35.0, ON) в пределах 10-15 секунд.
- **Время:** 23.11.2026, около 01:22.
- **Скриншот:** ![35](screens/08-value-change-35-grafana.png) ![curl и sqlite](screens/08b-value-change-35-curl-sqlite.png)

### 4. Потеря TEMP
- **Ожидание:** при остановке только TEMP возраст показаний растёт, правило переходит в Alerting; HUM и CTRL работают, `up` = 1; после восстановления правило возвращается в Normal.
- **Факт:** в узле «TEMP-01 каждые 5 с» отключён повтор, Node-RED продолжал работать. Правило перешло в Alerting, влажность 45.0 % и `up` = UP продолжали обновляться; после возврата повтора 5 с правило вернулось в Normal.
- **Время (по истории правила в Grafana):** Alerting 23.11.2026, 01:18:50 (возраст 27.8 с); Normal 23.11.2026, 01:21:30 (возраст 2.2 с).
- **Письмо:** не доставлено; SMTP в Grafana не настроен, у контактного адреса `email-lab01` статус «Last delivery attempt failed». Само оповещение видно в Alerting.
- **Подтверждение в SQLite:** у TEMP-01 записей меньше, чем у HUM-01 (909 против 945) из-за паузы.
- **Скриншоты:** ![до](screens/09-alert-normal-before.png) ![firing](screens/10-alert-firing.png) ![панель](screens/11-panel-age-red.png) ![после](screens/12-alert-normal-after.png) ![письмо](screens/13-contact-point-failed.png)

### 5. Сохранность
- **Ожидание:** после пересоздания контейнеров без удаления томов потоки и история остаются, отправка возобновляется.
- **Факт:** выполнена команда `docker compose up -d --force-recreate`. Все три контейнера снова Up; в SQLite осталось 1826 показаний (`measurements`), число продолжает расти; поток Node-RED на месте, Debug снова показывает 200. На следующий день (24.11) стенд проработал около 23 часов, в истории 14138 записей.
- **Время:** 23.11.2026, 02:11; повторная проверка 24.11.2026, 01:04.
- **Скриншоты:** ![recreate](screens/14-recreate-terminal.png) ![node-red](screens/15-nodered-after-recreate.png) ![стенд на следующий день](screens/15b-stack-after-overnight.png)

## Состояние стенда после испытаний
Период повтора TEMP и HUM возвращён к 5 секундам, температура в потоке 25 °C, влажность 45 %. Проверка: `office_temperature_celsius` = 25, `office_fan_on` = 0.

## Дополнительные скриншоты
![targets](screens/16-prometheus-targets-up.png) ![панель Grafana](screens/17-grafana-panel.png)
