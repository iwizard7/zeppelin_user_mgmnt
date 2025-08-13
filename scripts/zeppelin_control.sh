#!/bin/bash

# Скрипт для управления Apache Zeppelin на macOS

ZEPPELIN_HOME=/opt/zeppelin

case "$1" in
    start)
        echo "🚀 Запуск Apache Zeppelin..."
        $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start
        echo "🌐 Zeppelin будет доступен на: http://localhost:8080"
        ;;
    stop)
        echo "⏹️ Остановка Apache Zeppelin..."
        $ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop
        ;;
    restart)
        echo "⚡ Перезапуск Apache Zeppelin..."
        $ZEPPELIN_HOME/bin/zeppelin-daemon.sh restart
        ;;
    status)
        echo "📊 Статус Apache Zeppelin:"
        $ZEPPELIN_HOME/bin/zeppelin-daemon.sh status
        ;;
    logs)
        echo "📝 Логи Apache Zeppelin:"
        tail -f $ZEPPELIN_HOME/logs/zeppelin-*.log
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Команды:"
        echo "  start   - Запустить Zeppelin"
        echo "  stop    - Остановить Zeppelin"
        echo "  restart - Перезапустить Zeppelin"
        echo "  status  - Проверить статус"
        echo "  logs    - Показать логи"
        exit 1
        ;;
esac