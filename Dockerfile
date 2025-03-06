# Используем официальный образ Python
FROM python:3.13-slim AS builder

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файлы проекта в контейнер
COPY requirements.txt .

# Обновляем систему и устанавливаем libxml2
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y libxml2 && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем зависимости в отдельном слое
RUN pip install --no-cache-dir -r requirements.txt

# Используем минимальный образ для финального контейнера
FROM python:3.13-slim

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файлы проекта в контейнер
COPY . /app

# Копируем установленные зависимости из builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages

# Копируем установленные библиотеки из builder
COPY --from=builder /usr/lib/x86_64-linux-gnu/libxml2.so* /usr/lib/x86_64-linux-gnu/

# Открываем порт для доступа
EXPOSE 5000

# Запускаем приложение
CMD ["python", "app.py"]