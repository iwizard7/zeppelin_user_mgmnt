# 🔐 Руководство по безопасности

## Flask Secret Key

### Что это такое?
`app.secret_key` - это секретный ключ, который Flask использует для криптографической подписи данных.

### Для чего используется?
1. **Подписание сессий** - защита cookie сессий от подделки
2. **Flash сообщения** - безопасная передача уведомлений между запросами
3. **CSRF защита** - генерация токенов защиты от межсайтовых запросов
4. **Подписание cookie** - защита всех cookie от модификации

### В нашем приложении:
- **Аутентификация пользователей** - хранение информации о входе
- **Flash уведомления** - сообщения об успешных операциях и ошибках
- **Сессионная безопасность** - защита от подделки данных сессии

## Настройка для разных сред

### Разработка (Development)
```python
# Автоматическая генерация уникального ключа при каждом запуске
app.secret_key = 'dev-key-change-in-production-' + str(uuid.uuid4())
```

### Продакшен (Production)
```bash
# Установите переменную окружения
export SECRET_KEY="your-very-long-random-secret-key-here"

# Или в .env файле
SECRET_KEY=your-very-long-random-secret-key-here
```

```python
# В коде приложения
app.secret_key = os.environ.get('SECRET_KEY')
if not app.secret_key:
    raise ValueError("SECRET_KEY environment variable must be set in production")
```

### Docker
```dockerfile
# В Dockerfile
ENV SECRET_KEY=your-secret-key-here

# Или через docker-compose.yml
environment:
  - SECRET_KEY=your-secret-key-here
```

## Генерация безопасного ключа

### Способ 1: Python
```python
import secrets
secret_key = secrets.token_hex(32)
print(secret_key)  # Скопируйте этот ключ
```

### Способ 2: OpenSSL
```bash
openssl rand -hex 32
```

### Способ 3: Онлайн генератор
```bash
# Используйте команду для генерации случайного ключа
python -c "import secrets; print(secrets.token_hex(32))"
```

## Требования к безопасности

### ✅ Хорошие практики:
- **Длина**: Минимум 32 символа (рекомендуется 64)
- **Случайность**: Используйте криптографически стойкие генераторы
- **Уникальность**: Каждое приложение должно иметь свой ключ
- **Секретность**: Никогда не коммитьте ключ в Git
- **Ротация**: Периодически меняйте ключ

### ❌ Плохие практики:
- Простые пароли типа "password123"
- Хардкод ключа в исходном коде
- Использование одного ключа для всех приложений
- Публикация ключа в открытых репозиториях

## Настройка переменных окружения

### Linux/macOS
```bash
# Временно (до перезагрузки терминала)
export SECRET_KEY="your-secret-key-here"

# Постоянно (добавить в ~/.bashrc или ~/.zshrc)
echo 'export SECRET_KEY="your-secret-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### Windows
```cmd
# Временно
set SECRET_KEY=your-secret-key-here

# Постоянно (через системные настройки)
setx SECRET_KEY "your-secret-key-here"
```

### .env файл (с python-dotenv)
```bash
# Установка python-dotenv
pip install python-dotenv

# Создание .env файла
echo "SECRET_KEY=your-secret-key-here" > .env

# Добавление .env в .gitignore
echo ".env" >> .gitignore
```

```python
# В app.py
from dotenv import load_dotenv
load_dotenv()

app.secret_key = os.environ.get('SECRET_KEY')
```

## Проверка безопасности

### Текущая настройка
Наше приложение использует:
```python
app.secret_key = os.environ.get('SECRET_KEY', 'dev-key-change-in-production-' + str(uuid.uuid4()))
```

### Преимущества:
- ✅ Приоритет переменной окружения
- ✅ Автоматическая генерация для разработки
- ✅ Уникальный ключ при каждом запуске в dev-режиме
- ✅ Предупреждение о необходимости смены в продакшене

### Рекомендации:
1. **Для продакшена**: Обязательно установите переменную `SECRET_KEY`
2. **Для Docker**: Используйте Docker secrets или переменные окружения
3. **Для команды**: Документируйте процесс установки ключа
4. **Мониторинг**: Логируйте предупреждения о использовании dev-ключа

## Влияние на функциональность

### При смене ключа:
- **Сессии сбрасываются** - все пользователи будут разлогинены
- **Flash сообщения теряются** - текущие уведомления исчезнут
- **Cookie становятся недействительными** - потребуется повторный вход

### Планирование смены:
1. Уведомите пользователей о техническом обслуживании
2. Смените ключ в нерабочее время
3. Очистите старые сессии из хранилища (если используется)
4. Проверьте работоспособность после смены

## Дополнительная безопасность

### Настройки сессий:
```python
# Время жизни сессии
app.permanent_session_lifetime = timedelta(hours=8)

# Безопасные cookie (только для HTTPS)
app.config['SESSION_COOKIE_SECURE'] = True
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
```

### CSRF защита:
```python
from flask_wtf.csrf import CSRFProtect
csrf = CSRFProtect(app)
```

Правильная настройка `secret_key` - основа безопасности Flask приложения! 🔐