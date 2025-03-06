# Используем официальный образ Python
FROM python:alpine

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файлы проекта в контейнер
COPY . /app

# Обновляем систему и libxml2
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y libxml2 && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Открываем порт для доступа
EXPOSE 5000

# Запускаем приложение
CMD ["python", "app.py"]
