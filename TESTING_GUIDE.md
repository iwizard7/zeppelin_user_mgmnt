# 🧪 Руководство по тестированию

## Обзор тестов

### Структура тестов
```
tests/
└── test_app.py          # Основные тесты приложения
run_tests.sh             # Скрипт для локального запуска тестов
```

### Покрываемая функциональность
- ✅ **Страница логина** - загрузка и содержимое
- ✅ **Аутентификация** - успешный и неудачный вход
- ✅ **Защищенные маршруты** - требование авторизации
- ✅ **Dashboard** - доступ после входа
- ✅ **Logout** - выход из системы
- ✅ **Статические файлы** - доступность CSS/JS
- ✅ **API endpoints** - базовая проверка

## Локальный запуск тестов

### Быстрый запуск
```bash
./run_tests.sh
```

### Ручной запуск
```bash
# Активируем виртуальное окружение
source .venv/bin/activate

# Устанавливаем зависимости для тестов
pip install pytest pytest-flask pytest-cov

# Запускаем тесты
python -m pytest tests/ -v
```

### С покрытием кода
```bash
python -m pytest tests/ -v --cov=app --cov-report=html
```

## Автоматические тесты (GitHub Actions)

### Запуск в CI/CD
Тесты автоматически запускаются при:
- Каждом push в репозиторий
- Создании Pull Request
- На Python версиях: 3.8, 3.9, 3.10, 3.11

### Просмотр результатов
1. Перейдите в раздел **Actions** в GitHub
2. Выберите workflow **Tests**
3. Посмотрите результаты для каждой версии Python

## Описание тестов

### test_login_page()
**Назначение**: Проверка загрузки страницы входа
```python
def test_login_page(client):
    rv = client.get('/')
    assert rv.status_code == 200
    assert b'Login' in rv.data
```

### test_login_success()
**Назначение**: Проверка успешного входа
```python
def test_login_success(client):
    rv = client.post('/login', data={
        'username': 'admin',
        'password': 'admin123'
    }, follow_redirects=True)
    assert rv.status_code == 200
```

### test_login_failure()
**Назначение**: Проверка неудачного входа
```python
def test_login_failure(client):
    rv = client.post('/login', data={
        'username': 'wrong',
        'password': 'wrong'
    })
    assert rv.status_code == 302  # Redirect back to login
```

### test_dashboard_access_without_login()
**Назначение**: Проверка защиты dashboard от неавторизованного доступа
```python
def test_dashboard_access_without_login(client):
    rv = client.get('/dashboard')
    assert rv.status_code == 302  # Redirect to login
```

### test_dashboard_with_login()
**Назначение**: Проверка доступа к dashboard после входа
```python
def test_dashboard_with_login(client):
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    rv = client.get('/dashboard')
    assert rv.status_code == 200
    assert b'Zeppelin User Management' in rv.data
```

### test_protected_routes_require_login()
**Назначение**: Проверка что все защищенные маршруты требуют авторизации
```python
protected_routes = [
    '/dashboard', '/add_user', '/delete_user',
    '/add_role', '/assign_user_role', '/unassign_user_role',
    '/change_password', '/start_zeppelin', '/stop_zeppelin',
    '/restart', '/check_zeppelin_status'
]
```

## Добавление новых тестов

### Структура теста
```python
def test_new_functionality(client):
    """Test description"""
    # Arrange - подготовка данных
    
    # Act - выполнение действия
    rv = client.get('/some_endpoint')
    
    # Assert - проверка результата
    assert rv.status_code == 200
    assert b'expected_content' in rv.data
```

### Тестирование с авторизацией
```python
def test_authorized_action(client):
    # Логинимся
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    # Выполняем действие
    rv = client.post('/some_action', data={'param': 'value'})
    assert rv.status_code == 200
```

### Тестирование POST запросов
```python
def test_form_submission(client):
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    rv = client.post('/add_user', data={
        'username': 'newuser',
        'password': 'newpass'
    }, follow_redirects=True)
    
    assert rv.status_code == 200
    assert b'success_message' in rv.data
```

## Покрытие кода

### Текущее покрытие
- **Цель**: >80% покрытия кода
- **Отчеты**: Генерируются в `htmlcov/index.html`
- **CI/CD**: Интеграция с Codecov

### Просмотр отчета
```bash
# После запуска тестов с --cov-report=html
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## Моки и заглушки

### Мокирование внешних зависимостей
```python
from unittest.mock import patch, MagicMock

@patch('app.subprocess.run')
def test_zeppelin_control(mock_subprocess, client):
    mock_subprocess.return_value = MagicMock(returncode=0, stdout='OK')
    
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    rv = client.post('/start_zeppelin')
    assert rv.status_code == 302
    mock_subprocess.assert_called_once()
```

## Отладка тестов

### Запуск отдельного теста
```bash
python -m pytest tests/test_app.py::test_login_page -v
```

### Отладка с выводом
```bash
python -m pytest tests/ -v -s --tb=short
```

### Остановка на первой ошибке
```bash
python -m pytest tests/ -x
```

## Интеграция с IDE

### VS Code
Установите расширение **Python Test Explorer** для удобного запуска тестов

### PyCharm
Настройте pytest как test runner в настройках проекта

## Лучшие практики

### ✅ Хорошо
- Описательные имена тестов
- Один тест - одна проверка
- Использование фикстур для подготовки данных
- Проверка как успешных, так и ошибочных сценариев

### ❌ Избегайте
- Зависимости между тестами
- Тестирования внутренней реализации
- Слишком сложных тестов
- Игнорирования упавших тестов

Тесты - это документация вашего кода в действии! 📚