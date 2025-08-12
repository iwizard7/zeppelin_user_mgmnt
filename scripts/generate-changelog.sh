#!/bin/bash

# 📋 Автоматический генератор CHANGELOG
# Анализирует git историю и создает красивый changelog

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 Генерация CHANGELOG...${NC}"

# Получаем текущую версию
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")
echo -e "${BLUE}📌 Текущая версия: ${CURRENT_VERSION}${NC}"

# Создаем новую версию
NEW_VERSION="v$(date +%Y.%m.%d)"
echo -e "${BLUE}🆕 Новая версия: ${NEW_VERSION}${NC}"

# Получаем коммиты с последнего тега
if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    COMMITS=$(git log ${CURRENT_VERSION}..HEAD --oneline --no-merges)
else
    COMMITS=$(git log --oneline --no-merges)
fi

if [ -z "$COMMITS" ]; then
    echo -e "${YELLOW}⚠️ Нет новых коммитов с последнего релиза${NC}"
    exit 0
fi

# Функция для категоризации коммитов
categorize_commits() {
    local commits="$1"
    
    # Инициализируем категории
    FEATURES=""
    FIXES=""
    STYLES=""
    DOCS=""
    TESTS=""
    CI=""
    CHORES=""
    OTHERS=""
    
    while IFS= read -r commit; do
        if [ -z "$commit" ]; then continue; fi
        
        # Извлекаем хеш и сообщение
        HASH=$(echo "$commit" | awk '{print $1}')
        MESSAGE=$(echo "$commit" | cut -d' ' -f2-)
        
        # Категоризируем по префиксу
        case "$MESSAGE" in
            feat:*|feature:*)
                FEATURES="${FEATURES}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            fix:*|bugfix:*)
                FIXES="${FIXES}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            style:*|ui:*|ux:*)
                STYLES="${STYLES}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            docs:*|doc:*)
                DOCS="${DOCS}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            test:*|tests:*)
                TESTS="${TESTS}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            ci:*|build:*)
                CI="${CI}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            chore:*|refactor:*)
                CHORES="${CHORES}\n- ${MESSAGE#*: } (${HASH})"
                ;;
            *)
                # Пытаемся угадать по содержимому
                if echo "$MESSAGE" | grep -qi "fix\|bug\|error"; then
                    FIXES="${FIXES}\n- ${MESSAGE} (${HASH})"
                elif echo "$MESSAGE" | grep -qi "add\|new\|feature\|implement"; then
                    FEATURES="${FEATURES}\n- ${MESSAGE} (${HASH})"
                elif echo "$MESSAGE" | grep -qi "style\|css\|ui\|ux\|design"; then
                    STYLES="${STYLES}\n- ${MESSAGE} (${HASH})"
                elif echo "$MESSAGE" | grep -qi "doc\|readme\|guide"; then
                    DOCS="${DOCS}\n- ${MESSAGE} (${HASH})"
                elif echo "$MESSAGE" | grep -qi "test"; then
                    TESTS="${TESTS}\n- ${MESSAGE} (${HASH})"
                elif echo "$MESSAGE" | grep -qi "workflow\|ci\|build"; then
                    CI="${CI}\n- ${MESSAGE} (${HASH})"
                else
                    OTHERS="${OTHERS}\n- ${MESSAGE} (${HASH})"
                fi
                ;;
        esac
    done <<< "$COMMITS"
}

# Категоризируем коммиты
categorize_commits "$COMMITS"

# Создаем CHANGELOG
CHANGELOG_CONTENT="# 📋 CHANGELOG

## [${NEW_VERSION}] - $(date +%Y-%m-%d)

### 🎯 Обзор релиза
Автоматически сгенерированный changelog на основе git истории.
"

# Добавляем категории если они не пустые
if [ -n "$FEATURES" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### ✨ Новые возможности
${FEATURES}"
fi

if [ -n "$FIXES" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🐛 Исправления
${FIXES}"
fi

if [ -n "$STYLES" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🎨 UI/UX улучшения
${STYLES}"
fi

if [ -n "$DOCS" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 📚 Документация
${DOCS}"
fi

if [ -n "$TESTS" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🧪 Тесты
${TESTS}"
fi

if [ -n "$CI" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🔧 CI/CD и сборка
${CI}"
fi

if [ -n "$CHORES" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🏠 Техническое обслуживание
${CHORES}"
fi

if [ -n "$OTHERS" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 📦 Другие изменения
${OTHERS}"
fi

# Добавляем статистику
COMMIT_COUNT=$(echo "$COMMITS" | wc -l)
CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 📊 Статистика
- **Коммитов**: ${COMMIT_COUNT}
- **Дата релиза**: $(date +%Y-%m-%d)
- **Версия**: ${NEW_VERSION}

---
"

# Если существует старый CHANGELOG, добавляем к нему
if [ -f "CHANGELOG.md" ]; then
    # Читаем старый changelog (пропускаем первую строку заголовка)
    OLD_CHANGELOG=$(tail -n +2 CHANGELOG.md)
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}${OLD_CHANGELOG}"
fi

# Записываем новый CHANGELOG
echo -e "$CHANGELOG_CONTENT" > CHANGELOG.md

echo -e "${GREEN}✅ CHANGELOG.md обновлен!${NC}"

# Показываем превью
echo -e "${YELLOW}📋 Превью CHANGELOG:${NC}"
head -30 CHANGELOG.md

# Предлагаем создать тег и релиз
read -p "🏷️ Создать git тег ${NEW_VERSION}? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION

$(echo -e "$CHANGELOG_CONTENT" | head -20)"
    
    echo -e "${GREEN}✅ Тег ${NEW_VERSION} создан!${NC}"
    
    read -p "🚀 Отправить тег в GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin "$NEW_VERSION"
        echo -e "${GREEN}🎉 Тег отправлен! GitHub Release будет создан автоматически.${NC}"
    fi
fi