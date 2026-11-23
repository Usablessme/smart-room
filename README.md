# Умное помещение на одной виртуальной машине (LAB-01)

ПМ03 «Участие в разработке приложений взаимодействия с интеллектуальными
интегрированными системами». Индивидуальная практика.

Сокращённый стенд умного помещения на одной ВМ РЕД ОС 8 (VirtualBox):
два виртуальных датчика, автоматическое управление вентилятором,
хранение показаний в SQLite, мониторинг и оповещение.

## Назначение компонентов

| Компонент | Где работает | Назначение |
|---|---|---|
| Node-RED | контейнер `nodered` | Имитирует датчики TEMP-01 (температура серверной) и HUM-01 (влажность рабочей зоны) каждые 5 с, решает, включать ли вентилятор FAN-01, и отправляет данные по HTTP |
| CTRL (`ctrl/receiver.js`) | контейнер `ctrl` | Принимает показания и состояние FAN, отдаёт метрики Prometheus на `/metrics` |
| Storage (`db/server.py`) | контейнер `storage` | Принимает те же данные и записывает их в SQLite, показывает историю в браузере |
| SQLite (`db/data/telemetry.sqlite3`) | файл на ВМ | Хранилище. Файл и таблицы создаются вручную по `schema.sql` |
| Prometheus | системная служба РЕД ОС | Каждые 5 с собирает метрики CTRL |
| Grafana | системная служба РЕД ОС | Панель (температура, влажность, FAN, возраст TEMP, `up`) и правило оповещения |

## Схема

    Node-RED (TEMP, HUM, правило FAN)
       |-- POST /api/readings, /api/actuators --> CTRL :8080 --/metrics--> Prometheus :9090 --> Grafana :3000
       '-- POST /api/readings, /api/actuators --> storage :8081 --> SQLite (db/data)

Правило FAN-01: температура ниже 30 °C - OFF, 30 °C и выше - ON (режим `auto`).

## Адреса (в браузере внутри ВМ LAB-01)

| Компонент | Адрес | Из Node-RED |
|---|---|---|
| Node-RED | http://127.0.0.1:1880 | - |
| CTRL | http://127.0.0.1:8080/health, /metrics | http://ctrl:8080 |
| История SQLite | http://127.0.0.1:8081 | http://storage:8081 |
| Prometheus | http://127.0.0.1:9090 | - |
| Grafana | http://127.0.0.1:3000 | - |

Внутри контейнера `127.0.0.1` - это сам контейнер, поэтому соседние сервисы
указаны по именам `ctrl` и `storage`.

## Версии

РЕД ОС 8.0.3, Docker 29.7.2, Docker Compose 5.3.1, Node-RED 4.1 (образ
`nodered/node-red:4.1`), Node.js 22 и Python 3.13 (образы контейнеров),
SQLite 3.40.0, Prometheus 3.11.3, Grafana 13.3.0, Git 2.53.0.

## Структура репозитория

    compose.yml                     общий запуск nodered, ctrl, storage
    schema.sql                      создание таблиц SQLite (вручную)
    checks.sql                      проверочные запросы
    prometheus.yml                  настройка Prometheus
    ctrl/receiver.js                сервис CTRL (из раздаточных материалов)
    db/server.py                    сервис storage (из раздаточных материалов)
    db/index.html                   страница истории
    db/inspect_db.py                просмотр содержимого базы
    iot/flows.json                  потоки Node-RED
    docs/grafana-dashboard.json     экспорт панели Grafana
    docs/grafana-alert-rule.yaml    экспорт правила Grafana
    docs/                           инструкция, журнал испытаний, скриншоты

## Порядок запуска

1. Создать базу и таблицы вручную (storage сам базу не создаёт):

        mkdir -p db/data
        sqlite3 db/data/telemetry.sqlite3

   В консоли sqlite3 выполнить по одной строке: `.read schema.sql`, `.tables`,
   `.schema`, `PRAGMA quick_check;` (ответ `ok`), `.quit`.

2. Запустить контейнеры из корня проекта:

        docker compose config
        docker compose up -d

3. Открыть Node-RED (http://127.0.0.1:1880), меню -> Import -> вставить
   `iot/flows.json` -> Deploy.

4. Prometheus и Grafana установлены как службы:

        sudo dnf install -y golang-github-prometheus grafana
        sudo cp prometheus.yml /etc/prometheus/prometheus.yml
        sudo systemctl enable --now prometheus grafana-server

5. В Grafana: источник данных Prometheus `http://127.0.0.1:9090`, импорт
   `docs/grafana-dashboard.json`. Правило: Alerting -> Alert rules -> Import
   (файл `docs/grafana-alert-rule.yaml`). Контактный адрес Email и SMTP
   настраиваются отдельно, секреты в репозиторий не входят.

## Проверка

    curl http://127.0.0.1:8080/health
    curl http://127.0.0.1:8081/health
    curl -s http://127.0.0.1:8080/metrics | grep -E '^office_'
    sqlite3 -readonly -header -column db/data/telemetry.sqlite3 < checks.sql
    docker compose exec storage python inspect_db.py

- http://127.0.0.1:9090/targets: цель `office-controller` в статусе UP.
- http://127.0.0.1:8081: свежие записи TEMP-01, HUM-01, FAN-01.
- Grafana: панель «Умное помещение LAB-01», правило в состоянии Normal.

## Остановка и перезапуск

    docker compose down                      # остановить, данные остаются
    docker compose up -d                     # запустить снова
    docker compose up -d --force-recreate    # пересоздать контейнеры без потери данных

Не использовать `docker compose down -v`: флаг `-v` удаляет тома Node-RED.

## Безопасность

В репозиторий не включены: рабочая база SQLite, каталоги данных контейнеров,
пароли и SMTP-секреты (см. `.gitignore`).
