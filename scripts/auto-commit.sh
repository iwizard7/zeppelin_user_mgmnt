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

# Функция для создания детального описания
get_detailed_description() {
    local files="$1"
    local details=""
    
    # Анализируем конкретные изменения
    if echo "$files" | grep -q "favicon"; then
        details="${details}\n- Добавлен favicon и улучшен брендинг"
    fi
    
    if echo "$files" | grep -q "toast\|Toast"; then
        details="${details}\n- Добавлены toast уведомления"
    fi
    
    if echo "$files" | grep -q "theme"; then
        details="${details}\n- Улучшения системы тем"
    fi
    
    if echo "$files" | grep -q "search\|Search"; then
        details="${details}\n- Улучшения поиска и фильтрации"
    fi
    
    if echo "$files" | grep -q "login"; then
        details="${details}\n- Улучшения формы входа"
    fi
    
    if echo "$files" | grep -q "dashboard"; then
        details="${details}\n- Обновления dashboard"
    fi
    
    if echo "$files" | grep -q "workflow"; then
        details="${details}\n- Обновления GitHub Actions"
    fi
    
    if echo "$files" | grep -q "test"; then
        details="${details}\n- Обновления тестов"
    fi
    
    if echo "$files" | grep -q "\.md$"; then
        details="${details}\n- Обновление документации"
    fi
    
    echo -e "$details"
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

# Добавляем информацию о файлах
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
COMMIT_MESSAGE="${COMMIT_MESSAGE}

📁 Изменено файлов: ${FILE_COUNT}"

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