#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Node Exporter Standalone — инициализация ==="
echo

# Проверка Docker
if ! command -v docker &>/dev/null; then
  echo "Ошибка: Docker не найден. Установите Docker и запустите скрипт снова."
  exit 1
fi

# Существующий .env
if [[ -f .env ]]; then
  echo "Файл .env уже существует."
  read -r -p "Перезаписать? (y/N): " overwrite
  if [[ "${overwrite,,}" != "y" && "${overwrite,,}" != "yes" ]]; then
    echo "Выход без изменений."
    exit 0
  fi
  echo
fi

# Логин
read -r -p "Логин для Basic Auth [metrics]: " METRICS_USER
METRICS_USER="${METRICS_USER:-metrics}"

# Пароль (два ввода для проверки)
while true; do
  read -r -s -p "Пароль: " password
  echo
  if [[ -z "$password" ]]; then
    echo "Пароль не может быть пустым. Введите снова."
    continue
  fi
  read -r -s -p "Пароль (ещё раз): " password2
  echo
  if [[ "$password" != "$password2" ]]; then
    echo "Пароли не совпадают. Введите снова."
    continue
  fi
  break
done

echo
echo "Генерация хэша пароля через Caddy..."

# Пароль в контейнер через env — без stdin (избегаем EOF), спецсимволы сохраняются
PASSWORD_HASH=$(docker run --rm -e PASS="$password" caddy:alpine sh -c 'caddy hash-password --plaintext "$PASS"' 2>/dev/null)
unset password password2
if [[ -z "$PASSWORD_HASH" ]]; then
  echo "Не удалось сгенерировать хэш. Проверьте, что образ доступен: docker pull caddy:alpine"
  exit 1
fi

# Пишем .env
cat > .env << EOF
# Сгенерировано setup.sh $(date -Iseconds 2>/dev/null || date)

METRICS_USER=$METRICS_USER
METRICS_PASSWORD_HASH=$PASSWORD_HASH
EOF

echo "Создан файл .env (логин: $METRICS_USER)."
echo
echo "Дальше:"
echo "  docker compose up -d"
echo
echo "Проверка метрик:"
echo "  curl -u $METRICS_USER:<пароль> http://localhost:9100/metrics"
echo
