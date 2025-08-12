#!/bin/bash

# 🛑 Скрипт остановки Zeppelin User Management приложения

echo "🛑 Остановка Zeppelin User Management..."

# Ищем процессы приложения
APP_PIDS=$(ps aux | grep "app.py" | grep -v grep | awk '{print $2}')

if [ -z "$APP_PIDS" ]; then
    echo "ℹ️  Приложение не запущено"
    
    # Очищаем файл PID если он существует
    if [ -f ".app_pid" ]; then
        rm .app_pid
        echo "🧹 Очищен файл PID"
    fi
    
    exit 0
fi

echo "📊 Найденные процессы:"
ps aux | grep "app.py" | grep -v grep

echo ""
echo "🔄 Останавливаем процессы..."

# Останавливаем каждый процесс
for PID in $APP_PIDS; do
    echo "🛑 Останавливаем процесс $PID..."
    
    # Сначала пробуем мягкую остановку (SIGTERM)
    kill -TERM $PID 2>/dev/null
    
    # Ждем 5 секунд
    sleep 5
    
    # Проверяем, остановился ли процесс
    if ps -p $PID > /dev/null 2>&1; then
        echo "⚠️  Процесс $PID не остановился, принудительная остановка..."
        kill -KILL $PID 2>/dev/null
        sleep 2
        
        if ps -p $PID > /dev/null 2>&1; then
            echo "❌ Не удалось остановить процесс $PID"
        else
            echo "✅ Процесс $PID принудительно остановлен"
        fi
    else
        echo "✅ Процесс $PID корректно остановлен"
    fi
done

# Очищаем файл PID
if [ -f ".app_pid" ]; then
    rm .app_pid
    echo "🧹 Очищен файл PID"
fi

# Финальная проверка
REMAINING_PIDS=$(ps aux | grep "app.py" | grep -v grep | awk '{print $2}')
if [ -z "$REMAINING_PIDS" ]; then
    echo "✅ Все процессы приложения остановлены"
else
    echo "⚠️  Остались запущенные процессы:"
    ps aux | grep "app.py" | grep -v grep
fi

echo "🏁 Готово!"