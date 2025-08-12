#!/bin/bash

# 🔄 Скрипт перезапуска Zeppelin User Management приложения

echo "🔄 Перезапуск Zeppelin User Management..."
echo "======================================="

# Останавливаем приложение
echo "1️⃣ Остановка приложения..."
./stop_app.sh

# Ждем немного
echo ""
echo "⏳ Ожидание 3 секунды..."
sleep 3

# Запускаем приложение
echo ""
echo "2️⃣ Запуск приложения..."
./start_app.sh

echo ""
echo "🏁 Перезапуск завершен!"