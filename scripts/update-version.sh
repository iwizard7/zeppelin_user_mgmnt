#!/bin/bash

# 🔄 Скрипт обновления версии проекта

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Обновление версии проекта...${NC}"

# Проверяем аргументы
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}📝 Использование: $0 <новая_версия>${NC}"
    echo -e "${YELLOW}   Пример: $0 3.1.0${NC}"
    echo ""
    
    # Показываем текущую версию
    if [ -f "VERSION" ]; then
        CURRENT_VERSION=$(cat VERSION)
        echo -e "${BLUE}📋 Текущая версия: ${CURRENT_VERSION}${NC}"
    else
        echo -e "${YELLOW}⚠️ Файл VERSION не найден${NC}"
    fi
    
    exit 1
fi

NEW_VERSION="$1"

# Валидация формата версии (semantic versioning)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "${RED}❌ Неверный формат версии!${NC}"
    echo -e "${YELLOW}💡 Используйте формат: MAJOR.MINOR.PATCH (например: 3.1.0)${NC}"
    exit 1
fi

# Получаем текущую версию
if [ -f "VERSION" ]; then
    CURRENT_VERSION=$(cat VERSION)
    echo -e "${BLUE}📋 Текущая версия: ${CURRENT_VERSION}${NC}"
else
    CURRENT_VERSION="unknown"
    echo -e "${YELLOW}⚠️ Файл VERSION не найден, создаем новый${NC}"
fi

echo -e "${BLUE}🆕 Новая версия: ${NEW_VERSION}${NC}"

# Подтверждение
read -p "🤔 Продолжить обновление версии? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Обновление отменено${NC}"
    exit 0
fi

echo -e "${BLUE}🔄 Обновляем файлы...${NC}"

# 1. Обновляем файл VERSION
echo "$NEW_VERSION" > VERSION
echo -e "${GREEN}✅ Обновлен VERSION${NC}"

# 2. Обновляем README.md
if [ -f "README.md" ]; then
    # Обновляем версию в заголовке последних обновлений
    sed -i.bak "s/### v[0-9]\+\.[0-9]\+\.[0-9]\+/### v${NEW_VERSION}/g" README.md 2>/dev/null || \
    sed -i '' "s/### v[0-9]\+\.[0-9]\+\.[0-9]\+/### v${NEW_VERSION}/g" README.md 2>/dev/null || \
    echo -e "${YELLOW}⚠️ Не удалось обновить README.md автоматически${NC}"
    
    echo -e "${GREEN}✅ Обновлен README.md${NC}"
fi

# 3. Обновляем Readme.MD (если существует)
if [ -f "Readme.MD" ]; then
    sed -i.bak "s/### v[0-9]\+\.[0-9]\+\.[0-9]\+/### v${NEW_VERSION}/g" Readme.MD 2>/dev/null || \
    sed -i '' "s/### v[0-9]\+\.[0-9]\+\.[0-9]\+/### v${NEW_VERSION}/g" Readme.MD 2>/dev/null || \
    echo -e "${YELLOW}⚠️ Не удалось обновить Readme.MD автоматически${NC}"
    
    echo -e "${GREEN}✅ Обновлен Readme.MD${NC}"
fi

# 4. Обновляем package.json (если существует)
if [ -f "package.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"${NEW_VERSION}\"/g" package.json 2>/dev/null || \
    sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"${NEW_VERSION}\"/g" package.json 2>/dev/null
    echo -e "${GREEN}✅ Обновлен package.json${NC}"
fi

# 5. Обновляем setup.py (если существует)
if [ -f "setup.py" ]; then
    sed -i.bak "s/version='[^']*'/version='${NEW_VERSION}'/g" setup.py 2>/dev/null || \
    sed -i '' "s/version='[^']*'/version='${NEW_VERSION}'/g" setup.py 2>/dev/null
    echo -e "${GREEN}✅ Обновлен setup.py${NC}"
fi

# 6. Обновляем Docker файлы
if [ -f "Dockerfile" ]; then
    sed -i.bak "s/LABEL version=\"[^\"]*\"/LABEL version=\"${NEW_VERSION}\"/g" Dockerfile 2>/dev/null || \
    sed -i '' "s/LABEL version=\"[^\"]*\"/LABEL version=\"${NEW_VERSION}\"/g" Dockerfile 2>/dev/null || \
    echo -e "${YELLOW}⚠️ Не найден LABEL version в Dockerfile${NC}"
fi

# Очищаем backup файлы
rm -f *.bak 2>/dev/null || true

echo -e "${GREEN}🎉 Версия успешно обновлена!${NC}"
echo ""
echo -e "${BLUE}📋 Сводка изменений:${NC}"
echo -e "${BLUE}   Старая версия: ${CURRENT_VERSION}${NC}"
echo -e "${BLUE}   Новая версия:  ${NEW_VERSION}${NC}"
echo ""

# Показываем, что нужно сделать дальше
echo -e "${YELLOW}📝 Следующие шаги:${NC}"
echo -e "${YELLOW}   1. Проверьте изменения: git diff${NC}"
echo -e "${YELLOW}   2. Протестируйте приложение: ./scripts/start_app.sh${NC}"
echo -e "${YELLOW}   3. Сделайте коммит: git add . && git commit -m \"chore: bump version to ${NEW_VERSION}\"${NC}"
echo -e "${YELLOW}   4. Создайте тег: git tag v${NEW_VERSION}${NC}"
echo -e "${YELLOW}   5. Отправьте в GitHub: git push && git push --tags${NC}"

# Предлагаем автоматический коммит
echo ""
read -p "🤖 Создать автоматический коммит с новой версией? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add .
    git commit -m "chore: bump version to ${NEW_VERSION}

- Обновлена версия в VERSION файле
- Обновлены ссылки на версию в документации
- Версия теперь отображается в UI

📊 Версия: ${CURRENT_VERSION} → ${NEW_VERSION}"
    
    echo -e "${GREEN}✅ Коммит создан!${NC}"
    
    # Предлагаем создать тег
    read -p "🏷️ Создать git тег v${NEW_VERSION}? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}

🎯 Основные изменения:
- Обновлена версия до ${NEW_VERSION}
- Версия отображается в UI
- Синхронизация версий между компонентами

📅 Дата релиза: $(date +%Y-%m-%d)
🔗 Версия: v${NEW_VERSION}"
        
        echo -e "${GREEN}✅ Тег v${NEW_VERSION} создан!${NC}"
        
        # Предлагаем push
        read -p "🚀 Отправить изменения и тег в GitHub? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push && git push --tags
            echo -e "${GREEN}🎉 Все изменения отправлены в GitHub!${NC}"
        fi
    fi
fi

echo -e "${GREEN}🏁 Готово!${NC}"