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

# Функция для анализа изменений в файлах
analyze_file_changes() {
    local hash="$1"
    local changes=""
    
    # Получаем список измененных файлов в коммите
    local files=$(git show --name-only --format="" "$hash")
    
    # Анализируем типы файлов
    if echo "$files" | grep -q "app\.py"; then
        changes="${changes} Backend"
    fi
    if echo "$files" | grep -q "templates/"; then
        changes="${changes} UI"
    fi
    if echo "$files" | grep -q "static/.*\.css"; then
        changes="${changes} Styles"
    fi
    if echo "$files" | grep -q "static/.*\.js"; then
        changes="${changes} JavaScript"
    fi
    if echo "$files" | grep -q "\.github/workflows/"; then
        changes="${changes} CI/CD"
    fi
    if echo "$files" | grep -q "test"; then
        changes="${changes} Tests"
    fi
    if echo "$files" | grep -q "\.md$"; then
        changes="${changes} Docs"
    fi
    if echo "$files" | grep -q "requirements\.txt\|Dockerfile"; then
        changes="${changes} Build"
    fi
    if echo "$files" | grep -q "\.sh$"; then
        changes="${changes} Scripts"
    fi
    
    echo "$changes"
}

# Функция для получения статистики коммита
get_commit_stats() {
    local hash="$1"
    local stats=$(git show --stat --format="" "$hash" | tail -1)
    echo "$stats"
}

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
    MANAGEMENT=""
    WEBSOCKET=""
    SECURITY=""
    
    while IFS= read -r commit; do
        if [ -z "$commit" ]; then continue; fi
        
        # Извлекаем хеш и сообщение
        HASH=$(echo "$commit" | awk '{print $1}')
        MESSAGE=$(echo "$commit" | cut -d' ' -f2-)
        
        # Получаем дополнительную информацию
        FILE_CHANGES=$(analyze_file_changes "$HASH")
        COMMIT_STATS=$(get_commit_stats "$HASH")
        
        # Создаем расширенное описание
        EXTENDED_MESSAGE="$MESSAGE"
        if [ -n "$FILE_CHANGES" ]; then
            EXTENDED_MESSAGE="$MESSAGE [$FILE_CHANGES]"
        fi
        if [ -n "$COMMIT_STATS" ]; then
            EXTENDED_MESSAGE="$EXTENDED_MESSAGE ($COMMIT_STATS)"
        fi
        
        # Категоризируем по префиксу
        case "$MESSAGE" in
            feat:*|feature:*)
                FEATURES="${FEATURES}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            fix:*|bugfix:*)
                FIXES="${FIXES}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            style:*|ui:*|ux:*)
                STYLES="${STYLES}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            docs:*|doc:*)
                DOCS="${DOCS}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            test:*|tests:*)
                TESTS="${TESTS}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            ci:*|build:*)
                CI="${CI}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            chore:*|refactor:*)
                CHORES="${CHORES}\n- ${EXTENDED_MESSAGE#*: } \`${HASH}\`"
                ;;
            *)
                # Пытаемся угадать по содержимому
                if echo "$MESSAGE" | grep -qi "websocket\|socket\.io\|live.update"; then
                    WEBSOCKET="${WEBSOCKET}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "start_app\|stop_app\|status_app\|управление"; then
                    MANAGEMENT="${MANAGEMENT}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "security\|auth\|session\|login"; then
                    SECURITY="${SECURITY}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "fix\|bug\|error\|исправ"; then
                    FIXES="${FIXES}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "add\|new\|feature\|implement\|добав\|новый"; then
                    FEATURES="${FEATURES}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "style\|css\|ui\|ux\|design\|theme\|стил"; then
                    STYLES="${STYLES}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "doc\|readme\|guide\|документ"; then
                    DOCS="${DOCS}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "test\|тест"; then
                    TESTS="${TESTS}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                elif echo "$MESSAGE" | grep -qi "workflow\|ci\|build\|github.action"; then
                    CI="${CI}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
                else
                    OTHERS="${OTHERS}\n- ${EXTENDED_MESSAGE} \`${HASH}\`"
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

if [ -n "$WEBSOCKET" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### ⚡ WebSocket и Live Updates
${WEBSOCKET}"
fi

if [ -n "$MANAGEMENT" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🎛️ Управление приложением
${MANAGEMENT}"
fi

if [ -n "$SECURITY" ]; then
    CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 🔒 Безопасность и аутентификация
${SECURITY}"
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

# Добавляем детальную статистику
COMMIT_COUNT=$(echo "$COMMITS" | wc -l)

# Подсчитываем изменения по категориям
FEATURE_COUNT=$(echo -e "$FEATURES" | grep -c "^-" 2>/dev/null || echo "0")
FIX_COUNT=$(echo -e "$FIXES" | grep -c "^-" 2>/dev/null || echo "0")
STYLE_COUNT=$(echo -e "$STYLES" | grep -c "^-" 2>/dev/null || echo "0")
DOC_COUNT=$(echo -e "$DOCS" | grep -c "^-" 2>/dev/null || echo "0")
TEST_COUNT=$(echo -e "$TESTS" | grep -c "^-" 2>/dev/null || echo "0")
CI_COUNT=$(echo -e "$CI" | grep -c "^-" 2>/dev/null || echo "0")
WEBSOCKET_COUNT=$(echo -e "$WEBSOCKET" | grep -c "^-" 2>/dev/null || echo "0")
MANAGEMENT_COUNT=$(echo -e "$MANAGEMENT" | grep -c "^-" 2>/dev/null || echo "0")

# Получаем статистику изменений кода
if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    CODE_STATS=$(git diff --stat ${CURRENT_VERSION}..HEAD | tail -1)
else
    CODE_STATS=$(git log --stat --oneline | tail -1)
fi

CHANGELOG_CONTENT="${CHANGELOG_CONTENT}

### 📊 Статистика релиза
- **Общее количество коммитов**: ${COMMIT_COUNT}
- **Новые возможности**: ${FEATURE_COUNT}
- **Исправления**: ${FIX_COUNT}
- **UI/UX улучшения**: ${STYLE_COUNT}
- **WebSocket функции**: ${WEBSOCKET_COUNT}
- **Управление приложением**: ${MANAGEMENT_COUNT}
- **Документация**: ${DOC_COUNT}
- **Тесты**: ${TEST_COUNT}
- **CI/CD**: ${CI_COUNT}

### 📈 Изменения в коде
\`\`\`
${CODE_STATS}
\`\`\`

### 🏷️ Информация о релизе
- **Версия**: ${NEW_VERSION}
- **Дата релиза**: $(date +%Y-%m-%d)
- **Время релиза**: $(date +%H:%M:%S)
- **Предыдущая версия**: ${CURRENT_VERSION}

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