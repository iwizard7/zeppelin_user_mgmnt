# 🔐 Zeppelin User Management

Этот проект представляет собой веб-приложение для управления пользователями и ролями в файле конфигурации `shiro.ini` с возможностью перезапуска сервиса Apache Zeppelin.

## 🚀 Функционал
- 🔑 Авторизация пользователей
- 👥 Управление пользователями (добавление, удаление)
- 🎭 Управление ролями (добавление, назначение, удаление)
- 🔄 Перезапуск Apache Zeppelin
- ❇️ Запуск в Docker

## 🖼️ Интерфейс
Приложение предоставляет удобный веб-интерфейс для работы с пользователями и ролями. Все кнопки и поля ввода имеют единый стиль для лучшего UX.

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

Соберите образ:
```bash
docker build -t zeppelin_user_mgmnt .
```
Запустите контейнер:
```bash
docker run -d -p 5000:5000 --name zeppelin_user_mgmnt zeppelin_user_mgmnt
```
Приложение будет доступно по адресу http://localhost:5000/

## ❇️ Docker Compose (опционально)

Запустите docker-compose.yml:
```bash
docker-compose up -d --build
```
## ⚙️ Настройка shiro.ini
Приложение работает с файлом `shiro.ini`. Убедитесь, что прописан корректный путь до этого файла в переменной shiro_ini_path и файл имеет нужные права доступа.

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
Кнопка **Restart Zeppelin** выполняет команду:
```bash
sudo systemctl restart zeppelin
```
⚠️ Убедитесь, что ваш пользователь имеет права на выполнение этой команды.

## 📜 Лицензия
Этот проект распространяется под лицензией MIT.

## 💡 Авторы
- [iwizard7](https://github.com/iwizard7)

### ⭐️ Буду рад звезде на GitHub, если проект оказался полезен! 😊

