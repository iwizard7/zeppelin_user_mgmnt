#!/bin/bash

# 🚀 Скрипт запуска Zeppelin User Management приложения

echo "🚀 Запуск Zeppelin User Management..."

# Проверяем, не запущено ли уже приложение
if ps aux | grep "app.py" | grep -v grep > /dev/null; then
    echo "⚠️  Приложение уже запущено!"
    echo "📊 Процессы:"
    ps aux | grep "app.py" | grep -v grep
    echo ""
    echo "💡 Для остановки используйте: ./stop_app.sh"
    exit 1
fi

# Проверяем наличие виртуального окружения
if [ -d ".venv" ]; then
    echo "🔧 Активируем виртуальное окружение..."
    source .venv/bin/activate
else
    echo "⚠️  Виртуальное окружение не найдено"
    echo "💡 Создайте его командой: python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
fi

# Проверяем наличие зависимостей
if ! python3 -c "import flask, flask_socketio" 2>/dev/null; then
    echo "❌ Зависимости не установлены!"
    echo "💡 Установите их командой: pip install -r requirements.txt"
    exit 1
fi

# Проверяем наличие файла конфигурации
if [ ! -f "shiro.ini" ]; then
    echo "⚠️  Файл shiro.ini не найден!"
    echo "💡 Убедитесь, что файл конфигурации существует"
    exit 1
fi

# Создаем директорию для логов
mkdir -p logs

# Запускаем приложение в фоне
echo "🔄 Запускаем приложение..."
python3 app.py > logs/app_startup.log 2>&1 &
APP_PID=$!

# Ждем немного для инициализации
sleep 3

# Проверяем, что приложение запустилось
if ps -p $APP_PID > /dev/null; then
    echo "✅ Приложение успешно запущено!"
    echo "🆔 PID: $APP_PID"
    echo "🌐 URL: http://127.0.0.1:5003"
    echo "📝 Логи: logs/app_startup.log"
    echo ""
    echo "💡 Для остановки используйте: ./stop_app.sh"
    echo "📊 Для просмотра статуса: ./status_app.sh"
    
    # Сохраняем PID для удобства остановки
    echo $APP_PID > .app_pid
else
    echo "❌ Ошибка запуска приложения!"
    echo "📝 Проверьте логи: cat logs/app_startup.log"
    exit 1
fi