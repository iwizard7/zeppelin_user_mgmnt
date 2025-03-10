# 🚀 Управление пользователями Zeppelin

## 📋 Обзор
Этот проект предоставляет веб-интерфейс для управления пользователями и ролями в Apache Zeppelin с использованием файла `shiro.ini`. Включает функции для добавления, удаления и назначения ролей пользователям, а также перезапуска службы Zeppelin.

## ✨ Возможности
- 🔐 **Управление пользователями**: добавление, удаление и управление пользователями.
- 🛡️ **Управление ролями**: добавление и назначение ролей пользователям.
- 🔄 **Перезапуск Zeppelin**: перезапуск службы Zeppelin одним кликом.
- 🌐 **Веб-интерфейс**: удобный веб-интерфейс для управления пользователями и ролями.

## 📦 Установка и запуск

### 1️⃣ Клонирование репозитория
```bash
git clone https://github.com/iwizard7/zeppelin_user_mgmnt.git
cd zeppelin_user_mgmnt
```

### 2️⃣ Установка зависимостей
Убедитесь, что у вас установлен Python 3.
```bash
pip install flask
```

### 3️⃣ Запуск приложения
```bash
python app.py
```
Приложение будет доступно по адресу: [http://127.0.0.1:5000](http://127.0.0.1:5000)

## ❇️ Запуск в Docker

### Сборка образа
```bash
docker build -t zeppelin_user_mgmnt .
```

### Запуск контейнера
```bash
docker run -d -p 5000:5000 --name zeppelin_user_mgmnt zeppelin_user_mgmnt
```
Приложение будет доступно по адресу: [http://localhost:5000](http://localhost:5000)

## ❇️ Docker Compose (опционально)

### Запуск с Docker Compose
```bash
docker-compose up -d --build
```

## ⚙️ Настройка `shiro.ini`
Убедитесь, что указан корректный путь к файлу `shiro.ini` в переменной `shiro_ini_path` и файл имеет необходимые права доступа.

Пример структуры `shiro.ini`:
```
[users]
admin = admin123, admin
user1 = pass1, role1
user2 = pass2, role2

[roles]
admin = *
role1 = *
role2 = *
```

## 🔄 Перезапуск Apache Zeppelin
Кнопка **Restart Zeppelin** выполняет:
```bash
sudo systemctl stop zeppelin
sleep(30)
sudo systemctl start zeppelin
```
⚠️ Убедитесь, что ваш пользователь имеет права на выполнение этой команды.

## 📜 Лицензия
Этот проект распространяется под лицензией MIT.

## 💡 Авторы
- [iwizard7](https://github.com/iwizard7)

### ⭐️ Буду рад звезде на GitHub, если проект оказался полезен! 😊