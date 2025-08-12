#!/bin/bash

# 🔗 Настройка Git hooks для автоматизации
# Устанавливает хуки для автоматических commit сообщений

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔗 Настройка Git hooks...${NC}"

# Создаем директорию hooks если её нет
mkdir -p .git/hooks

# Создаем prepare-commit-msg hook
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash

# Автоматическое улучшение commit сообщений
# Добавляет эмодзи и форматирование

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Пропускаем если это merge или уже есть сообщение
if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "squash" ]; then
    exit 0
fi

# Читаем текущее сообщение
CURRENT_MSG=$(cat "$COMMIT_MSG_FILE")

# Пропускаем если сообщение уже отформатировано
if echo "$CURRENT_MSG" | grep -q "^[a-z]*:"; then
    exit 0
fi

# Анализируем изменения
CHANGED_FILES=$(git diff --cached --name-only)

# Определяем тип изменений и добавляем эмодзи
if echo "$CHANGED_FILES" | grep -q "\.github/workflows/"; then
    PREFIX="🔧 ci: "
elif echo "$CHANGED_FILES" | grep -q "test"; then
    PREFIX="🧪 test: "
elif echo "$CHANGED_FILES" | grep -q "\.md$"; then
    PREFIX="📚 docs: "
elif echo "$CHANGED_FILES" | grep -q "static/.*\.css\|static/.*\.js"; then
    PREFIX="🎨 style: "
elif echo "$CHANGED_FILES" | grep -q "templates/\|app\.py"; then
    PREFIX="✨ feat: "
elif echo "$CHANGED_FILES" | grep -q "requirements\.txt\|Dockerfile"; then
    PREFIX="📦 build: "
else
    PREFIX="🔄 update: "
fi

# Обновляем сообщение
echo "${PREFIX}${CURRENT_MSG}" > "$COMMIT_MSG_FILE"
EOF

# Делаем hook исполняемым
chmod +x .git/hooks/prepare-commit-msg

echo -e "${GREEN}✅ Git hooks настроены!${NC}"
echo -e "${YELLOW}📝 Теперь ваши commit сообщения будут автоматически улучшаться${NC}"
echo -e "${BLUE}💡 Используйте: git commit -m 'ваше сообщение'${NC}"