#!/bin/bash

# ==========================================
# Настройки
# ==========================================
# Точное имя твоего VPN соединения в NetworkManager
VPN_NAME="antizapret-client-(fi-aeza-01.e-lenta.ru)"
NMCLI="/usr/bin/nmcli"

# ==========================================
# Основная логика (Непрерывное чтение логов)
# ==========================================

echo "Запуск мониторинга логов VPN для '$VPN_NAME'..."
logger -t vpn-watchdog "Запущен мониторинг логов nm-openvpn"

# Команда journalctl:
# -t nm-openvpn : читаем логи только от процесса nm-openvpn
# -f            : follow (читаем в реальном времени бесконечно)
# -n 0          : не выводить старые логи при запуске, только новые
journalctl -t nm-openvpn -f -n 0 | while read -r line; do

    # Проверяем, содержит ли новая строка лога одну из наших ошибок
    if [[ "$line" == *"Inactivity timeout (--ping-restart)"* ]] || 
       [[ "$line" == *"[ECONNREFUSED]"* ]] || 
       [[ "$line" == *"No route to host"* ]]; then
        
        # Записываем в системный журнал, что мы поймали ошибку
        logger -t vpn-watchdog "Поймано событие падения: $line"
        logger -t vpn-watchdog "Инициирую перезапуск VPN '$VPN_NAME'..."

        # Проверяем, числится ли VPN как "активный" в NetworkManager
        IS_ACTIVE=$("$NMCLI" -t -f NAME connection show --active | grep -x "$VPN_NAME")
        
        if [ -n "$IS_ACTIVE" ]; then
            # Выключаем
            "$NMCLI" connection down "$VPN_NAME"
            
            # Ждем пару секунд, чтобы интерфейсы успели удалиться из системы
            sleep 3
            
            # Включаем обратно
            if "$NMCLI" connection up "$VPN_NAME"; then
                logger -t vpn-watchdog "VPN '$VPN_NAME' успешно перезапущен."
            else
                logger -t vpn-watchdog "Ошибка при попытке поднять VPN '$VPN_NAME'."
            fi
            
            # Небольшая пауза после перезапуска, чтобы не реагировать 
            # на старые логи, если они вдруг "долетят"
            sleep 5
        else
            logger -t vpn-watchdog "VPN '$VPN_NAME' выключен пользователем, игнорирую событие."
        fi
        
    fi

done
