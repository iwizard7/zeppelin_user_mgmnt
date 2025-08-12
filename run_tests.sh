#!/bin/bash

echo "🧪 Запуск тестов для Zeppelin User Management..."

# Проверяем наличие виртуального окружения
if [ ! -d ".venv" ]; then
    echo "⚠️  Виртуальное окружение не найдено. Создаем..."
    python3 -m venv .venv
fi

# Активируем виртуальное окружение
source .venv/bin/activate

# Устанавливаем зависимости для тестирования
echo "📦 Устанавливаем зависимости для тестирования..."
pip install -q pytest pytest-flask pytest-cov

# Устанавливаем основные зависимости
pip install -q -r requirements.txt

# Создаем тестовый shiro.ini если его нет
if [ ! -f "shiro.ini" ]; then
    echo "📝 Создаем тестовый shiro.ini..."
    cat > shiro.ini << EOF
[users]
admin = admin123, admin
testuser = testpass, user

[roles]
admin = *
user = notebook:read
EOF
fi

# Создаем директорию для логов
mkdir -p logs

# Запускаем тесты
echo "🚀 Запускаем тесты..."
python -m pytest tests/ -v --cov=app --cov-report=term-missing --cov-report=html

# Показываем результаты покрытия
if [ -d "htmlcov" ]; then
    echo ""
    echo "📊 Отчет о покрытии создан в htmlcov/index.html"
    echo "Откройте файл в браузере для детального просмотра"
fi

echo ""
echo "✅ Тестирование завершено!"