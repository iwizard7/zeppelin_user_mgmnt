# 🍎 Установка Apache Zeppelin на macOS

## Быстрая установка

### 1. Предварительные требования
```bash
# Проверьте Java (должна быть 8+)
java -version

# Если Java нет, установите:
brew install openjdk@11
```

### 2. Установка Apache Zeppelin
```bash
# Скачайте Zeppelin
curl -O https://archive.apache.org/dist/zeppelin/zeppelin-0.10.1/zeppelin-0.10.1-bin-all.tgz

# Распакуйте и установите
tar -xzf zeppelin-0.10.1-bin-all.tgz
sudo mv zeppelin-0.10.1-bin-all /opt/zeppelin

# Очистите
rm zeppelin-0.10.1-bin-all.tgz
```

### 3. Настройка окружения
```bash
# Добавьте в ~/.zshrc
echo 'export ZEPPELIN_HOME=/opt/zeppelin' >> ~/.zshrc
echo 'export PATH=$PATH:$ZEPPELIN_HOME/bin' >> ~/.zshrc

# Перезагрузите терминал или выполните:
source ~/.zshrc
```

### 4. Настройка конфигурации
```bash
# Создайте конфигурационный файл
sudo cp /opt/zeppelin/conf/zeppelin-env.sh.template /opt/zeppelin/conf/zeppelin-env.sh

# Отключите Hadoop
echo 'export USE_HADOOP=false' | sudo tee -a /opt/zeppelin/conf/zeppelin-env.sh

# Скопируйте shiro.ini из проекта
sudo cp shiro.ini /opt/zeppelin/conf/shiro.ini
```

### 5. Запуск и тестирование
```bash
# Запустите Zeppelin
./zeppelin_control.sh start

# Проверьте статус
./zeppelin_control.sh status

# Запустите приложение управления
./run_app.sh
```

### 6. Проверка работы
- Zeppelin: http://localhost:8080
- Управление: http://localhost:5003
- Войдите как admin/1234 в оба интерфейса

## Управление

### Команды Zeppelin
```bash
./zeppelin_control.sh start    # Запуск
./zeppelin_control.sh stop     # Остановка
./zeppelin_control.sh restart  # Перезапуск
./zeppelin_control.sh status   # Статус
./zeppelin_control.sh logs     # Логи
```

### Команды приложения
```bash
./run_app.sh                   # Запуск приложения управления
```

## Устранение проблем

### Zeppelin не запускается
```bash
# Проверьте Java
java -version

# Проверьте права доступа
ls -la /opt/zeppelin/

# Проверьте логи
tail -f /opt/zeppelin/logs/zeppelin-*.log
```

### Приложение не видит Zeppelin
```bash
# Убедитесь, что ZEPPELIN_HOME установлен
echo $ZEPPELIN_HOME

# Проверьте путь к daemon скрипту
ls -la /opt/zeppelin/bin/zeppelin-daemon.sh
```

### Проблемы с правами
```bash
# Исправьте права на директорию Zeppelin
sudo chown -R $(whoami):staff /opt/zeppelin/logs
sudo chown -R $(whoami):staff /opt/zeppelin/run
```