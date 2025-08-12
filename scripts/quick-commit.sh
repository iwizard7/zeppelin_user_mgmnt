#!/bin/bash

# 🚀 Быстрый коммит - упрощенная версия
# Использование: ./scripts/quick-commit.sh [сообщение]

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Если передано сообщение, используем его
if [ -n "$1" ]; then
    COMMIT_MESSAGE="$*"
    echo -e "${BLUE}📝 Используем переданное сообщение: ${COMMIT_MESSAGE}${NC}"
else
    # Иначе запускаем автоматический анализ
    echo -e "${BLUE}🤖 Запускаем автоматический анализ...${NC}"
    ./scripts/auto-commit.sh
    exit 0
fi

# Проверяем есть ли изменения
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️ Нет изменений для коммита${NC}"
    exit 0
fi

# Делаем коммит
git add .
git commit -m "$COMMIT_MESSAGE"

echo -e "${GREEN}✅ Коммит выполнен: ${COMMIT_MESSAGE}${NC}"

# Предлагаем push
read -p "🚀 Отправить в GitHub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
    echo -e "${GREEN}🎉 Изменения отправлены!${NC}"
fi