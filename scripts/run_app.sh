#!/bin/bash

echo "🚀 Запуск приложения управления Zeppelin..."

# Активируем виртуальное окружение
source .venv/bin/activate

# Устанавливаем переменную окружения для Zeppelin
export ZEPPELIN_HOME=/opt/zeppelin

# Запускаем приложение
python app.py