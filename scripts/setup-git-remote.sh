#!/bin/bash

# 🔧 Скрипт настройки git remote

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Настройка git remote...${NC}"

# Проверяем текущие remote
echo -e "${BLUE}📡 Текущие git remote:${NC}"
if git remote -v 2>/dev/null | grep -q .; then
    git remote -v
    echo ""
    
    read -p "🤔 Хотите изменить существующий remote? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Настройка отменена${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠️ Git remote не настроен${NC}"
fi

# Получаем URL репозитория
echo -e "${BLUE}🔗 Введите URL вашего GitHub репозитория:${NC}"
echo -e "${YELLOW}Пример: https://github.com/username/repository.git${NC}"
read -p "URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}❌ URL не может быть пустым${NC}"
    exit 1
fi

# Проверяем формат URL
if [[ ! "$REPO_URL" =~ ^https://github\.com/.+/.+\.git$ ]] && [[ ! "$REPO_URL" =~ ^git@github\.com:.+/.+\.git$ ]]; then
    echo -e "${YELLOW}⚠️ URL не похож на GitHub репозиторий${NC}"
    read -p "🤔 Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Настройка отменена${NC}"
        exit 0
    fi
fi

# Определяем имя remote
REMOTE_NAME="origin"
if git remote | grep -q "^origin$"; then
    echo -e "${YELLOW}⚠️ Remote 'origin' уже существует${NC}"
    read -p "🔄 Заменить существующий remote? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Удаляем старый remote...${NC}"
        git remote remove origin
    else
        # Предлагаем другое имя
        read -p "📝 Введите имя для нового remote (по умолчанию 'main'): " CUSTOM_NAME
        REMOTE_NAME=${CUSTOM_NAME:-main}
        
        if git remote | grep -q "^${REMOTE_NAME}$"; then
            echo -e "${RED}❌ Remote '${REMOTE_NAME}' уже существует${NC}"
            exit 1
        fi
    fi
fi

# Добавляем remote
echo -e "${BLUE}➕ Добавляем remote '${REMOTE_NAME}'...${NC}"
if git remote add "$REMOTE_NAME" "$REPO_URL"; then
    echo -e "${GREEN}✅ Remote успешно добавлен!${NC}"
else
    echo -e "${RED}❌ Ошибка добавления remote${NC}"
    exit 1
fi

# Проверяем соединение
echo -e "${BLUE}🔍 Проверяем соединение с репозиторием...${NC}"
if git ls-remote "$REMOTE_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Соединение успешно!${NC}"
else
    echo -e "${RED}❌ Не удается подключиться к репозиторию${NC}"
    echo -e "${YELLOW}💡 Проверьте:${NC}"
    echo -e "${YELLOW}   - Правильность URL${NC}"
    echo -e "${YELLOW}   - Права доступа к репозиторию${NC}"
    echo -e "${YELLOW}   - Настройки SSH ключей (для SSH URL)${NC}"
    
    read -p "🗑️ Удалить неработающий remote? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote remove "$REMOTE_NAME"
        echo -e "${YELLOW}🗑️ Remote удален${NC}"
    fi
    exit 1
fi

# Показываем итоговую конфигурацию
echo -e "${GREEN}🎉 Настройка завершена!${NC}"
echo -e "${BLUE}📋 Текущие remote:${NC}"
git remote -v

# Предлагаем установить upstream
if [ "$REMOTE_NAME" = "origin" ]; then
    CURRENT_BRANCH=$(git branch --show-current)
    if [ -n "$CURRENT_BRANCH" ]; then
        read -p "🔗 Установить upstream для ветки '${CURRENT_BRANCH}'? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if git push -u "$REMOTE_NAME" "$CURRENT_BRANCH"; then
                echo -e "${GREEN}✅ Upstream установлен!${NC}"
            else
                echo -e "${YELLOW}⚠️ Не удалось установить upstream${NC}"
                echo -e "${YELLOW}💡 Возможно, ветка не существует на remote${NC}"
            fi
        fi
    fi
fi

echo -e "${GREEN}🚀 Теперь вы можете использовать git push и скрипты автоматизации!${NC}"