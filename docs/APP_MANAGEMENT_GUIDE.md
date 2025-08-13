# 🔧 Руководство по управлению приложением

## 📋 Обзор
Данное руководство описывает, как корректно запускать, останавливать и управлять Zeppelin User Management приложением.

## 🚀 Скрипты управления

### 1. Запуск приложения
```bash
./start_app.sh
```

**Что делает скрипт:**
- ✅ Проверяет, не запущено ли уже приложение
- ✅ Активирует виртуальное окружение (если существует)
- ✅ Проверяет наличие зависимостей
- ✅ Проверяет наличие файла конфигурации `shiro.ini`
- ✅ Создает директорию для логов
- ✅ Запускает приложение в фоновом режиме
- ✅ Сохраняет PID процесса для удобства управления

**Вывод при успешном запуске:**
```
🚀 Запуск Zeppelin User Management...
🔧 Активируем виртуальное окружение...
🔄 Запускаем приложение...
✅ Приложение успешно запущено!
🆔 PID: 12345
🌐 URL: http://127.0.0.1:5003
📝 Логи: logs/app_startup.log

💡 Для остановки используйте: ./stop_app.sh
📊 Для просмотра статуса: ./status_app.sh
```

### 2. Остановка приложения
```bash
./stop_app.sh
```

**Что делает скрипт:**
- ✅ Находит все процессы приложения
- ✅ Показывает информацию о найденных процессах
- ✅ Выполняет мягкую остановку (SIGTERM)
- ✅ При необходимости выполняет принудительную остановку (SIGKILL)
- ✅ Очищает файлы PID
- ✅ Проверяет, что все процессы остановлены

**Вывод при успешной остановке:**
```
🛑 Остановка Zeppelin User Management...
📊 Найденные процессы:
user   12345  0.0  0.3  app.py
🔄 Останавливаем процессы...
🛑 Останавливаем процесс 12345...
✅ Процесс 12345 корректно остановлен
🧹 Очищен файл PID
✅ Все процессы приложения остановлены
🏁 Готово!
```

### 3. Проверка статуса
```bash
./status_app.sh
```

**Что показывает скрипт:**
- ✅ Статус приложения (запущено/остановлено)
- ✅ Информация о процессах (PID, время работы, использование ресурсов)
- ✅ Открытые порты
- ✅ Доступность веб-интерфейса
- ✅ Информация о логах
- ✅ Команды управления

**Вывод при запущенном приложении:**
```
📊 Статус Zeppelin User Management
==================================
🟢 Статус: ЗАПУЩЕНО

📋 Активные процессы:
  🆔 PID: 12345
     📊 12345  1234  01:23:45  0.1  0.3  python3 app.py
     🌐 Порты: 5003

🌐 Проверка веб-интерфейса:
  ✅ http://127.0.0.1:5003 - ДОСТУПЕН

📝 Логи:
  📄 logs/app.log - 150 строк
  📋 Последние записи:
     2025-08-12 15:48:21 - INFO - User: admin, Action: LOGIN_SUCCESS
     2025-08-12 15:48:22 - INFO - WebSocket подключение: admin
     2025-08-12 15:48:51 - INFO - User: admin, Action: CHECK_ZEPPELIN_STATUS

🔧 Управление:
  🛑 Остановить: ./stop_app.sh
  🔄 Перезапустить: ./stop_app.sh && ./start_app.sh
  📝 Логи: tail -f logs/app.log
```

### 4. Перезапуск приложения
```bash
./restart_app.sh
```

**Что делает скрипт:**
- ✅ Останавливает приложение
- ✅ Ждет 3 секунды
- ✅ Запускает приложение заново

## 🔧 Ручное управление

### Запуск в фоне
```bash
python3 app.py &
```

### Поиск процессов
```bash
ps aux | grep "app.py" | grep -v grep
```

### Остановка по PID
```bash
kill -TERM <PID>
# или принудительно:
kill -KILL <PID>
```

### Проверка портов
```bash
lsof -i :5003
```

## 📝 Логирование

### Основные лог файлы
- **`logs/app.log`** - основной лог приложения с ротацией
- **`logs/app_startup.log`** - лог запуска приложения

### Просмотр логов в реальном времени
```bash
tail -f logs/app.log
```

### Просмотр последних записей
```bash
tail -20 logs/app.log
```

### Поиск в логах
```bash
grep "ERROR" logs/app.log
grep "LOGIN" logs/app.log
```

## 🚨 Решение проблем

### Приложение не запускается

1. **Проверьте зависимости:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Проверьте файл конфигурации:**
   ```bash
   ls -la shiro.ini
   ```

3. **Проверьте логи запуска:**
   ```bash
   cat logs/app_startup.log
   ```

4. **Проверьте порт:**
   ```bash
   lsof -i :5003
   ```

### Приложение не останавливается

1. **Найдите процессы:**
   ```bash
   ps aux | grep "app.py"
   ```

2. **Принудительная остановка:**
   ```bash
   pkill -f "app.py"
   ```

3. **Очистите PID файл:**
   ```bash
   rm -f .app_pid
   ```

### Порт занят

1. **Найдите процесс, использующий порт:**
   ```bash
   lsof -i :5003
   ```

2. **Остановите процесс:**
   ```bash
   kill -TERM <PID>
   ```

3. **Или измените порт в app.py:**
   ```python
   socketio.run(app, host='0.0.0.0', port=5004, debug=False, allow_unsafe_werkzeug=True)
   ```

### Проблемы с виртуальным окружением

1. **Создайте виртуальное окружение:**
   ```bash
   python3 -m venv .venv
   ```

2. **Активируйте его:**
   ```bash
   source .venv/bin/activate
   ```

3. **Установите зависимости:**
   ```bash
   pip install -r requirements.txt
   ```

## 🔄 Автоматический запуск

### Создание systemd сервиса (Linux)
```bash
sudo tee /etc/systemd/system/zeppelin-user-mgmt.service > /dev/null <<EOF
[Unit]
Description=Zeppelin User Management
After=network.target

[Service]
Type=simple
User=your_user
WorkingDirectory=/path/to/zeppelin_user_mgmnt
ExecStart=/path/to/zeppelin_user_mgmnt/.venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zeppelin-user-mgmt
sudo systemctl start zeppelin-user-mgmt
```

### Создание launchd сервиса (macOS)
```bash
tee ~/Library/LaunchAgents/com.zeppelin.user.mgmt.plist > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zeppelin.user.mgmt</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/zeppelin_user_mgmnt/.venv/bin/python</string>
        <string>/path/to/zeppelin_user_mgmnt/app.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/zeppelin_user_mgmnt</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.zeppelin.user.mgmt.plist
```

## 📊 Мониторинг

### Проверка ресурсов
```bash
# CPU и память
ps -p <PID> -o pid,ppid,etime,pcpu,pmem,command

# Открытые файлы
lsof -p <PID>

# Сетевые соединения
netstat -p <PID>
```

### Автоматический мониторинг
```bash
# Создайте скрипт мониторинга
cat > monitor_app.sh << 'EOF'
#!/bin/bash
while true; do
    if ! ps aux | grep "app.py" | grep -v grep > /dev/null; then
        echo "$(date): Приложение остановлено, перезапускаем..."
        ./start_app.sh
    fi
    sleep 60
done
EOF

chmod +x monitor_app.sh
nohup ./monitor_app.sh &
```

---

**💡 Совет**: Всегда используйте предоставленные скрипты для управления приложением, они обеспечивают корректную работу и логирование всех операций.