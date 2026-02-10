# Node Exporter (standalone) с Basic Auth

Переносимый набор для запуска Node Exporter на любой Linux-машине. Метрики защищены HTTP Basic Auth; доступ — по одному порту **9100**.

## Быстрый старт

1. **Скопируйте эту папку** на целевой сервер (например `node-exporter-standalone/`).

2. **Инициализация** — запустите скрипт, он спросит логин и пароль и создаст `.env`:
   ```bash
   ./setup.sh
   ```
   Либо создайте `.env` вручную: скопируйте `.env.example`, сгенерируйте хэш пароля (`docker run --rm caddy:alpine caddy hash-password`, ввод с stdin) и подставьте в `METRICS_PASSWORD_HASH`.

3. **Запуск:**
   ```bash
   docker compose up -d
   ```

4. **Проверка** (с этой же машины, подставьте свой логин и пароль):
   ```bash
   curl -u metrics:ваш_пароль http://localhost:9100/metrics
   ```

Снаружи метрики будут по адресу `http://IP_СЕРВЕРА:9100/metrics` с тем же логином и паролем.

---

## Настройка Prometheus (скрапинг с Basic Auth)

На сервере, где крутится Prometheus, в `prometheus.yml` добавьте задачу с `basic_auth`:

```yaml
scrape_configs:
  - job_name: node-remote
    scrape_interval: 15s
    basic_auth:
      username: metrics
      password: ваш_пароль
    static_configs:
      - targets: ["IP_УДАЛЁННОГО_СЕРВЕРА:9100"]
    metrics_path: /metrics
    scheme: http
```

Либо храните пароль в файле и подставляйте через `password_file` (см. документацию Prometheus).

---

## Состав

| Сервис          | Назначение |
|-----------------|------------|
| `node-exporter` | Сбор метрик хоста (LA, память, диски, CPU, сеть). Внутренняя сеть, наружу не публикуется. |
| `metrics-auth`  | Caddy: слушает порт 9100, проверяет Basic Auth, проксирует запросы на node-exporter. |

Один раз настроили `.env` — один и тот же compose можно использовать на любом количестве серверов (на каждом свой пароль в `.env` при желании).
