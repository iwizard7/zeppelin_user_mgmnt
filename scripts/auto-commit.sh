#!/bin/bash

# 🤖 Автоматический коммит с умными сообщениями
# Анализирует изменения и создает осмысленные commit сообщения

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Автоматический анализ изменений...${NC}"

# Проверяем есть ли изменения
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️ Нет изменений для коммита${NC}"
    exit 0
fi

# Получаем список измененных файлов
CHANGED_FILES=$(git status --porcelain | awk '{print $2}')
ADDED_FILES=$(git status --porcelain | grep "^A" | awk '{print $2}')
MODIFIED_FILES=$(git status --porcelain | grep "^M" | awk '{print $2}')
DELETED_FILES=$(git status --porcelain | grep "^D" | awk '{print $2}')

echo -e "${BLUE}📁 Анализируем файлы:${NC}"
echo "$CHANGED_FILES"

# Функция для определения типа изменений
get_commit_type() {
    local files="$1"
    
    # Проверяем типы файлов
    if echo "$files" | grep -q "\.github/workflows/"; then
        echo "ci"
    elif echo "$files" | grep -q "test"; then
        echo "test"
    elif echo "$files" | grep -q "\.md$"; then
        echo "docs"
    elif echo "$files" | grep -q "static/.*\.css\|static/.*\.js"; then
        echo "style"
    elif echo "$files" | grep -q "templates/"; then
        echo "feat"
    elif echo "$files" | grep -q "app\.py"; then
        echo "feat"
    elif echo "$files" | grep -q "requirements\.txt\|Dockerfile\|docker-compose"; then
        echo "build"
    elif echo "$files" | grep -q "\.gitignore\|\.env"; then
        echo "chore"
    else
        echo "update"
    fi
}

# Функция для создания описания изменений
get_commit_description() {
    local files="$1"
    local type="$2"
    
    case $type in
        "feat")
            if echo "$files" | grep -q "templates/login"; then
                echo "улучшения формы входа и UX"
            elif echo "$files" | grep -q "templates/dashboard"; then
                echo "улучшения dashboard и функциональности"
            elif echo "$files" | grep -q "app\.py"; then
                echo "новая функциональность и улучшения backend"
            else
                echo "новые возможности и улучшения"
            fi
            ;;
        "style")
            if echo "$files" | grep -q "themes\.css"; then
                echo "обновление стилей и тем"
            elif echo "$files" | grep -q "\.js"; then
                echo "улучшения JavaScript и интерактивности"
            else
                echo "обновление стилей и UI"
            fi
            ;;
        "ci")
            echo "обновление CI/CD workflows и автоматизации"
            ;;
        "test")
            echo "добавление и улучшение тестов"
            ;;
        "docs")
            echo "обновление документации"
            ;;
        "build")
            echo "обновление конфигурации сборки и зависимостей"
            ;;
        "chore")
            echo "техническое обслуживание и настройки"
            ;;
        *)
            echo "обновления проекта"
            ;;
    esac
}

# Функция для анализа изменений в коде
analyze_code_changes() {
    local files="$1"
    local changes=""
    
    # Анализируем изменения в Python коде
    if echo "$files" | grep -q "app\.py"; then
        # Проверяем добавленные строки в app.py
        if git diff --cached app.py | grep -q "socketio\|WebSocket"; then
            changes="${changes}\n- WebSocket функциональность"
        fi
        if git diff --cached app.py | grep -q "session\|Session"; then
            changes="${changes}\n- Управление сессиями"
        fi
        if git diff --cached app.py | grep -q "def.*user\|def.*role"; then
            changes="${changes}\n- Управление пользователями и ролями"
        fi
        if git diff --cached app.py | grep -q "zeppelin\|Zeppelin"; then
            changes="${changes}\n- Интеграция с Zeppelin"
        fi
        if git diff --cached app.py | grep -q "log\|Log"; then
            changes="${changes}\n- Система логирования"
        fi
    fi
    
    # Анализируем изменения в templates
    if echo "$files" | grep -q "templates/"; then
        if git diff --cached templates/ | grep -q "theme\|Theme"; then
            changes="${changes}\n- Система тем в UI"
        fi
        if git diff --cached templates/ | grep -q "search\|Search"; then
            changes="${changes}\n- Поиск и фильтрация"
        fi
        if git diff --cached templates/ | grep -q "toast\|Toast"; then
            changes="${changes}\n- Toast уведомления"
        fi
        if git diff --cached templates/ | grep -q "websocket\|WebSocket"; then
            changes="${changes}\n- WebSocket интеграция в UI"
        fi
    fi
    
    # Анализируем изменения в CSS/JS
    if echo "$files" | grep -q "static/"; then
        if git diff --cached static/ | grep -q "animation\|transition"; then
            changes="${changes}\n- Анимации и переходы"
        fi
        if git diff --cached static/ | grep -q "dark\|light\|theme"; then
            changes="${changes}\n- Темная/светлая тема"
        fi
        if git diff --cached static/ | grep -q "hover\|focus"; then
            changes="${changes}\n- Интерактивные эффекты"
        fi
    fi
    
    echo -e "$changes"
}

# Функция для создания детального описания
get_detailed_description() {
    local files="$1"
    local details=""
    
    # Анализируем конкретные изменения по файлам
    if echo "$files" | grep -q "favicon"; then
        details="${details}\n- 🚀 Добавлен кастомный favicon с ракетой"
    fi
    
    if echo "$files" | grep -q "start_app\.sh\|stop_app\.sh\|status_app\.sh\|restart_app\.sh"; then
        details="${details}\n- 🎛️ Добавлены скрипты управления приложением"
    fi
    
    if echo "$files" | grep -q "toast\|Toast"; then
        details="${details}\n- 📢 Добавлены современные toast уведомления"
    fi
    
    if echo "$files" | grep -q "theme"; then
        details="${details}\n- 🌙 Улучшения системы тем (dark/light mode)"
    fi
    
    if echo "$files" | grep -q "search\|Search"; then
        details="${details}\n- 🔍 Улучшения поиска и фильтрации пользователей"
    fi
    
    if echo "$files" | grep -q "login"; then
        details="${details}\n- 🔐 Улучшения формы входа и аутентификации"
    fi
    
    if echo "$files" | grep -q "dashboard"; then
        details="${details}\n- 📊 Обновления dashboard и основного интерфейса"
    fi
    
    if echo "$files" | grep -q "workflow"; then
        details="${details}\n- 🤖 Обновления GitHub Actions и CI/CD"
    fi
    
    if echo "$files" | grep -q "test"; then
        details="${details}\n- 🧪 Обновления автоматических тестов"
    fi
    
    if echo "$files" | grep -q "\.md$"; then
        details="${details}\n- 📚 Обновление документации и руководств"
    fi
    
    if echo "$files" | grep -q "requirements\.txt"; then
        details="${details}\n- 📦 Обновление зависимостей Python"
    fi
    
    if echo "$files" | grep -q "Dockerfile\|docker-compose"; then
        details="${details}\n- 🐳 Обновление Docker конфигурации"
    fi
    
    # Добавляем анализ изменений в коде
    local code_changes=$(analyze_code_changes "$files")
    if [ -n "$code_changes" ]; then
        details="${details}\n\n🔧 Изменения в коде:${code_changes}"
    fi
    
    echo -e "$details"
}

# Функция для получения статистики изменений
get_change_stats() {
    local added_lines=$(git diff --cached --numstat | awk '{sum += $1} END {print sum}')
    local deleted_lines=$(git diff --cached --numstat | awk '{sum += $2} END {print sum}')
    local modified_files=$(git diff --cached --name-only | wc -l)
    
    echo "📊 Статистика: +${added_lines:-0} -${deleted_lines:-0} строк в ${modified_files} файлах"
}

# Определяем тип коммита
COMMIT_TYPE=$(get_commit_type "$CHANGED_FILES")
COMMIT_DESCRIPTION=$(get_commit_description "$CHANGED_FILES" "$COMMIT_TYPE")
DETAILED_DESCRIPTION=$(get_detailed_description "$CHANGED_FILES")

# Создаем commit сообщение
COMMIT_MESSAGE="${COMMIT_TYPE}: ${COMMIT_DESCRIPTION}"

# Добавляем детали если есть
if [ -n "$DETAILED_DESCRIPTION" ]; then
    COMMIT_MESSAGE="${COMMIT_MESSAGE}

${DETAILED_DESCRIPTION}"
fi

# Добавляем статистику изменений
CHANGE_STATS=$(get_change_stats)
COMMIT_MESSAGE="${COMMIT_MESSAGE}

${CHANGE_STATS}"

# Добавляем список измененных файлов если их немного
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
if [ "$FILE_COUNT" -le 10 ]; then
    COMMIT_MESSAGE="${COMMIT_MESSAGE}

📁 Измененные файлы:"
    echo "$CHANGED_FILES" | while read file; do
        if [ -n "$file" ]; then
            COMMIT_MESSAGE="${COMMIT_MESSAGE}
- $file"
        fi
    done
else
    COMMIT_MESSAGE="${COMMIT_MESSAGE}

📁 Изменено файлов: ${FILE_COUNT}"
fi

echo -e "${GREEN}📝 Сгенерированное commit сообщение:${NC}"
echo -e "${YELLOW}${COMMIT_MESSAGE}${NC}"

# Спрашиваем подтверждение
read -p "🤔 Выполнить коммит с этим сообщением? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Добавляем все изменения
    git add .
    
    # Делаем коммит
    git commit -m "$COMMIT_MESSAGE"
    
    echo -e "${GREEN}✅ Коммит выполнен успешно!${NC}"
    
    # Предлагаем push
    read -p "🚀 Отправить изменения в GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push
        echo -e "${GREEN}🎉 Изменения отправлены в GitHub!${NC}"
    fi
else
    echo -e "${YELLOW}❌ Коммит отменен${NC}"
fi