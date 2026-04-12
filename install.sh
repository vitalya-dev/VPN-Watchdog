#!/bin/bash

# Получаем абсолютный путь к текущей директории
PROJECT_DIR=$(pwd)
SERVICE_NAME="vpn-watchdog.service"
SCRIPT_NAME="vpn-watchdog.sh"
TARGET_DIR="$HOME/.config/systemd/user"

echo "🔧 Начинаю установку vpn-watchdog..."

# 1. Проверяем наличие файлов
if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo "❌ Ошибка: Файл $SCRIPT_NAME не найден в текущей директории!"
    exit 1
fi

# 2. Делаем скрипты исполняемыми
chmod +x "$SCRIPT_NAME"
[[ -f "vpn-resume.sh" ]] && chmod +x "vpn-resume.sh"

# 3. Создаем папку для пользовательских сервисов, если её нет
mkdir -p "$TARGET_DIR"

# 4. Прописываем актуальный путь в файл сервиса перед копированием
echo "📝 Настраиваю пути в $SERVICE_NAME..."
sed -i "s|ExecStart=.*|ExecStart=$PROJECT_DIR/$SCRIPT_NAME|" "$SERVICE_NAME"

# 5. Копируем файл сервиса
cp "$SERVICE_NAME" "$TARGET_DIR/"

# 6. Перезагружаем конфиги systemd
echo "🔄 Перезапуск демона systemd..."
systemctl --user daemon-reload

# 7. Включаем и запускаем сервис
echo "🚀 Запуск сервиса..."
systemctl --user enable "$SERVICE_NAME"
systemctl --user restart "$SERVICE_NAME"

echo "-----------------------------------------------"
echo "✅ Установка завершена успешно!"
echo "Статус сервиса:"
systemctl --user status "$SERVICE_NAME" --no-pager
echo "-----------------------------------------------"
echo "💡 Совет: чтобы сервис работал после закрытия терминала/выхода из системы,"
echo "выполни один раз: sudo loginctl enable-linger $USER"
