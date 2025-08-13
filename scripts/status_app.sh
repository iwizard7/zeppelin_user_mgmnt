#!/bin/bash

# 📊 Скрипт проверки статуса Zeppelin User Management приложения

echo "📊 Статус Zeppelin User Management"
echo "=================================="

# Проверяем процессы приложения
APP_PIDS=$(ps aux | grep "app.py" | grep -v grep | awk '{print $2}')

if [ -z "$APP_PIDS" ]; then
    echo "🔴 Статус: ОСТАНОВЛЕНО"
    echo "ℹ️  Приложение не запущено"
    
    # Проверяем файл PID
    if [ -f ".app_pid" ]; then
        OLD_PID=$(cat .app_pid)
        echo "⚠️  Найден старый PID файл: $OLD_PID (процесс не активен)"
    fi
    
    echo ""
    echo "💡 Для запуска используйте: ./start_app.sh"
    exit 0
fi

echo "🟢 Статус: ЗАПУЩЕНО"
echo ""

# Показываем информацию о процессах
echo "📋 Активные процессы:"
for PID in $APP_PIDS; do
    echo "  🆔 PID: $PID"
    
    # Получаем информацию о процессе
    if command -v ps > /dev/null; then
        PS_INFO=$(ps -p $PID -o pid,ppid,etime,pcpu,pmem,command --no-headers 2>/dev/null)
        if [ ! -z "$PS_INFO" ]; then
            echo "     📊 $PS_INFO"
        fi
    fi
    
    # Проверяем порты (если доступен lsof)
    if command -v lsof > /dev/null; then
        PORTS=$(lsof -p $PID -i -P -n 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2 | sort -u)
        if [ ! -z "$PORTS" ]; then
            echo "     🌐 Порты: $(echo $PORTS | tr '\n' ' ')"
        fi
    fi
    
    echo ""
done

# Проверяем доступность веб-интерфейса
echo "🌐 Проверка веб-интерфейса:"
if command -v curl > /dev/null; then
    if curl -s --connect-timeout 3 http://127.0.0.1:5003 > /dev/null; then
        echo "  ✅ http://127.0.0.1:5003 - ДОСТУПЕН"
    else
        echo "  ❌ http://127.0.0.1:5003 - НЕ ДОСТУПЕН"
    fi
else
    echo "  ℹ️  curl не установлен, проверьте вручную: http://127.0.0.1:5003"
fi

# Проверяем логи
echo ""
echo "📝 Логи:"
if [ -f "logs/app.log" ]; then
    LOG_SIZE=$(wc -l < logs/app.log 2>/dev/null || echo "0")
    echo "  📄 logs/app.log - $LOG_SIZE строк"
    
    # Показываем последние записи
    echo "  📋 Последние записи:"
    tail -3 logs/app.log 2>/dev/null | sed 's/^/     /'
else
    echo "  ⚠️  Основной лог файл не найден"
fi

if [ -f "logs/app_startup.log" ]; then
    STARTUP_SIZE=$(wc -l < logs/app_startup.log 2>/dev/null || echo "0")
    echo "  📄 logs/app_startup.log - $STARTUP_SIZE строк"
fi

echo ""
echo "🔧 Управление:"
echo "  🛑 Остановить: ./stop_app.sh"
echo "  🔄 Перезапустить: ./stop_app.sh && ./start_app.sh"
echo "  📝 Логи: tail -f logs/app.log"