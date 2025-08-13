# Используем официальный образ Python
FROM python:3.13-slim

# Метаданные образа
LABEL version="3.0.0"
LABEL description="Zeppelin User Management - Modern web interface for Apache Zeppelin user management"
LABEL maintainer="iwizard7"

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файлы проекта в контейнер, исключая shiro.ini
COPY . /app

# Обновляем систему и устанавливаем libxml2
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y libxml2 && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --upgrade pip

# Set the user to avoid permission issues
RUN useradd -ms /bin/bash appuser
RUN chown -R appuser:appuser /app
USER appuser


# Открываем порт для доступа
EXPOSE 5000

# Запускаем приложение
CMD ["python", "app.py"]