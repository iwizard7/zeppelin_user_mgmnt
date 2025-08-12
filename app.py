from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_socketio import SocketIO, emit, disconnect
import os
import time
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timedelta
from functools import wraps
import subprocess
import platform
import uuid
import threading
import json

app = Flask(__name__)

# Настройка секретного ключа (для продакшена используйте переменную окружения)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-key-change-in-production-' + str(uuid.uuid4()))
app.permanent_session_lifetime = timedelta(hours=8)  # Сессия истекает через 8 часов

# Инициализация SocketIO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')
shiro_ini_path = 'shiro.ini'

# Защищенные пользователи, которых нельзя удалять или изменять
PROTECTED_USERS = {'admin'}


def is_protected_user(username):
    """
    Проверяет, является ли пользователь защищенным
    
    Args:
        username (str): Имя пользователя
    
    Returns:
        bool: True если пользователь защищен
    """
    return username.lower() in PROTECTED_USERS


def detect_zeppelin_installation():
    """
    Определяет способ установки и запуска Zeppelin
    
    Returns:
        dict: Информация о способе запуска Zeppelin
    """
    # Проверяем наличие systemd сервиса
    try:
        result = subprocess.run(['systemctl', 'list-unit-files', 'zeppelin.service'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and 'zeppelin.service' in result.stdout:
            return {'type': 'systemd', 'available': True}
    except:
        pass
    
    # Проверяем наличие zeppelin-daemon.sh
    common_paths = [
        '/opt/zeppelin/bin/zeppelin-daemon.sh',
        '/usr/local/zeppelin/bin/zeppelin-daemon.sh',
        '/home/*/zeppelin*/bin/zeppelin-daemon.sh',
        './bin/zeppelin-daemon.sh',
        '../zeppelin/bin/zeppelin-daemon.sh'
    ]
    
    import glob
    for path_pattern in common_paths:
        matches = glob.glob(path_pattern)
        if matches:
            return {'type': 'daemon', 'available': True, 'path': matches[0]}
    
    # Проверяем переменную окружения ZEPPELIN_HOME
    zeppelin_home = os.environ.get('ZEPPELIN_HOME')
    if zeppelin_home:
        daemon_path = os.path.join(zeppelin_home, 'bin', 'zeppelin-daemon.sh')
        if os.path.exists(daemon_path):
            return {'type': 'daemon', 'available': True, 'path': daemon_path}
    
    return {'type': 'unknown', 'available': False}


def get_system_info():
    """
    Определяет операционную систему и команды управления сервисами
    
    Returns:
        dict: Информация о системе и командах
    """
    system = platform.system()
    zeppelin_info = detect_zeppelin_installation()
    
    if system == 'Darwin':  # macOS
        # Сначала проверяем, есть ли zeppelin-daemon.sh
        if zeppelin_info['type'] == 'daemon':
            daemon_path = zeppelin_info['path']
            return {
                'os': 'macOS',
                'service_manager': 'zeppelin-daemon.sh',
                'demo_mode': False,
                'zeppelin_type': 'daemon',
                'daemon_path': daemon_path,
                'commands': {
                    'status': [daemon_path, 'status'],
                    'start': [daemon_path, 'start'],
                    'stop': [daemon_path, 'stop'],
                    'restart': [daemon_path, 'restart']
                }
            }
        else:
            # Fallback к демо-режиму если daemon не найден
            return {
                'os': 'macOS',
                'service_manager': 'launchctl',
                'demo_mode': True,
                'zeppelin_type': 'demo',
                'commands': {
                    'status': ['launchctl', 'list', 'org.apache.zeppelin'],
                    'start': ['launchctl', 'start', 'org.apache.zeppelin'],
                    'stop': ['launchctl', 'stop', 'org.apache.zeppelin'],
                    'restart': ['launchctl', 'kickstart', '-k', 'system/org.apache.zeppelin']
                }
            }
    elif system == 'Linux':
        # Определяем дистрибутив Linux
        try:
            with open('/etc/os-release', 'r') as f:
                os_release = f.read().lower()
            
            if 'centos' in os_release or 'rhel' in os_release or 'red hat' in os_release:
                distro = 'CentOS/RHEL'
            elif 'oracle' in os_release:
                distro = 'Oracle Linux'
            elif 'ubuntu' in os_release or 'debian' in os_release:
                distro = 'Ubuntu/Debian'
            else:
                distro = 'Linux'
        except:
            distro = 'Linux'
        
        # Выбираем команды в зависимости от способа установки Zeppelin
        if zeppelin_info['type'] == 'systemd':
            return {
                'os': distro,
                'service_manager': 'systemctl',
                'demo_mode': False,
                'zeppelin_type': 'systemd',
                'commands': {
                    'status': ['sudo', 'systemctl', 'status', 'zeppelin'],
                    'is_active': ['sudo', 'systemctl', 'is-active', 'zeppelin'],
                    'is_enabled': ['sudo', 'systemctl', 'is-enabled', 'zeppelin'],
                    'start': ['sudo', 'systemctl', 'start', 'zeppelin'],
                    'stop': ['sudo', 'systemctl', 'stop', 'zeppelin'],
                    'restart': ['sudo', 'systemctl', 'restart', 'zeppelin']
                }
            }
        elif zeppelin_info['type'] == 'daemon':
            daemon_path = zeppelin_info['path']
            return {
                'os': distro,
                'service_manager': 'zeppelin-daemon.sh',
                'demo_mode': False,
                'zeppelin_type': 'daemon',
                'daemon_path': daemon_path,
                'commands': {
                    'status': [daemon_path, 'status'],
                    'start': [daemon_path, 'start'],
                    'stop': [daemon_path, 'stop'],
                    'restart': [daemon_path, 'restart']
                }
            }
        else:
            # Fallback к systemctl если daemon не найден
            return {
                'os': distro,
                'service_manager': 'systemctl',
                'demo_mode': False,
                'zeppelin_type': 'systemd',
                'commands': {
                    'status': ['sudo', 'systemctl', 'status', 'zeppelin'],
                    'is_active': ['sudo', 'systemctl', 'is-active', 'zeppelin'],
                    'is_enabled': ['sudo', 'systemctl', 'is-enabled', 'zeppelin'],
                    'start': ['sudo', 'systemctl', 'start', 'zeppelin'],
                    'stop': ['sudo', 'systemctl', 'stop', 'zeppelin'],
                    'restart': ['sudo', 'systemctl', 'restart', 'zeppelin']
                }
            }
    else:
        return {
            'os': system,
            'service_manager': 'unknown',
            'demo_mode': True,
            'zeppelin_type': 'unknown',
            'commands': {}
        }

# Настройка логирования с ротацией
def setup_logging():
    """Настраивает логирование с ротацией файлов"""
    # Создаем директорию для логов если её нет
    log_dir = 'logs'
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    # Настраиваем RotatingFileHandler
    # Максимальный размер файла: 10MB, количество backup файлов: 5
    file_handler = RotatingFileHandler(
        filename=os.path.join(log_dir, 'app.log'),
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5,
        encoding='utf-8'
    )
    
    # Настраиваем консольный вывод
    console_handler = logging.StreamHandler()
    
    # Устанавливаем формат логов
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    # Настраиваем logger
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

# Инициализируем логирование
logger = setup_logging()


@app.before_request
def check_session_timeout():
    """Проверяет истечение сессии перед каждым запросом"""
    # Исключаем статические файлы и страницу логина
    if request.endpoint in ['static', 'login_page', 'login']:
        return
    
    if 'username' in session:
        # Проверяем время последней активности
        if 'last_activity' in session:
            last_activity = session['last_activity']
            if isinstance(last_activity, str):
                last_activity = datetime.fromisoformat(last_activity)
            
            # Если прошло больше 8 часов - завершаем сессию
            if datetime.now() - last_activity > timedelta(hours=8):
                username = session.get('username', 'unknown')
                log_user_action('SESSION_TIMEOUT', username, 'Session expired after 8 hours')
                session.clear()
                flash('Сессия истекла. Войдите в систему снова.', 'warning')
                return redirect(url_for('login_page'))
        
        # Обновляем время последней активности
        session['last_activity'] = datetime.now().isoformat()
        session.permanent = True


def login_required(f):
    """Декоратор для проверки авторизации"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            flash('Необходимо войти в систему', 'error')
            return redirect(url_for('login_page'))
        return f(*args, **kwargs)
    return decorated_function


def validate_input(data, field_name, min_length=1, max_length=50):
    """Валидация входных данных"""
    if not data or not data.strip():
        return False, f'{field_name} не может быть пустым'
    
    data = data.strip()
    if len(data) < min_length:
        return False, f'{field_name} должно содержать минимум {min_length} символов'
    
    if len(data) > max_length:
        return False, f'{field_name} не может содержать более {max_length} символов'
    
    # Проверка на недопустимые символы
    if any(char in data for char in ['=', '[', ']', '\n', '\r']):
        return False, f'{field_name} содержит недопустимые символы'
    
    return True, data


def log_user_action(action, username, details=None):
    """
    Логирует действия пользователей
    
    Args:
        action (str): Тип действия
        username (str): Имя пользователя
        details (str): Дополнительные детали
    """
    client_ip = request.remote_addr if request else 'unknown'
    log_message = f"User: {username}, Action: {action}, IP: {client_ip}"
    if details:
        log_message += f", Details: {details}"
    logger.info(log_message)


def read_shiro_ini():
    """
    Reads the shiro.ini file and parses its contents into users, roles, and sections.
    Preserves all sections and their original formatting.

    Returns:
        tuple: A tuple containing three dictionaries:
            - users (dict): A dictionary of users with their passwords and roles.
            - roles (dict): A dictionary of roles with their permissions.
            - sections (dict): A dictionary of sections with their original lines.
    """
    users = {}
    roles = {}
    sections = {}
    current_section = None
    section_order = []  # Сохраняем порядок секций

    try:
        with open(shiro_ini_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except FileNotFoundError:
        logger.error(f"Файл {shiro_ini_path} не найден")
        flash(f'Файл конфигурации {shiro_ini_path} не найден', 'error')
        return users, roles, sections
    except PermissionError:
        logger.error(f"Нет прав доступа к файлу {shiro_ini_path}")
        flash('Нет прав доступа к файлу конфигурации', 'error')
        return users, roles, sections
    except Exception as e:
        logger.error(f"Ошибка чтения файла {shiro_ini_path}: {str(e)}")
        flash('Ошибка чтения файла конфигурации', 'error')
        return users, roles, sections

    # Сначала читаем все строки и определяем секции
    for i, line in enumerate(lines):
        stripped_line = line.strip()

        # Определяем начало новой секции
        if stripped_line.startswith('[') and stripped_line.endswith(']'):
            current_section = stripped_line[1:-1]
            if current_section not in sections:
                sections[current_section] = []
                section_order.append(current_section)

        # Добавляем строку в текущую секцию (включая заголовок секции)
        if current_section:
            sections[current_section].append(line)
        else:
            # Строки до первой секции (комментарии в начале файла)
            if 'header' not in sections:
                sections['header'] = []
                section_order.insert(0, 'header')
            sections['header'].append(line)

        # Парсим пользователей только из секции [users]
        if current_section == 'users' and '=' in stripped_line and not stripped_line.startswith('['):
            parts = stripped_line.split('=', 1)  # Разделяем только по первому знаку =
            if len(parts) == 2:
                username, data = parts[0].strip(), parts[1].strip()
                data_parts = [part.strip() for part in data.split(',') if part.strip()]
                if data_parts:
                    users[username] = {'password': data_parts[0], 'roles': data_parts[1:]}

        # Парсим роли только из секции [roles]
        elif current_section == 'roles' and '=' in stripped_line and not stripped_line.startswith('['):
            parts = stripped_line.split('=', 1)  # Разделяем только по первому знаку =
            if len(parts) == 2:
                role = parts[0].strip()
                roles[role] = parts[1].strip()

    # Сохраняем порядок секций
    sections['_section_order'] = section_order
    
    logger.info(f"Прочитано пользователей: {len(users)}, ролей: {len(roles)}, секций: {len(section_order)}")
    
    return users, roles, sections


def write_shiro_ini(users, roles, sections):
    """
    Writes the users, roles, and sections back to the shiro.ini file.
    Preserves all sections and their original formatting, only modifying [users] and [roles].

    Args:
        users (dict): A dictionary of users with their passwords and roles.
        roles (dict): A dictionary of roles with their permissions.
        sections (dict): A dictionary of sections with their original lines.
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Создаем резервную копию
        backup_path = f"{shiro_ini_path}.backup"
        if os.path.exists(shiro_ini_path):
            with open(shiro_ini_path, 'r', encoding='utf-8') as src:
                with open(backup_path, 'w', encoding='utf-8') as dst:
                    dst.write(src.read())
        
        logger.info(f"Начинаем запись в {shiro_ini_path}")
        logger.info(f"Пользователей для записи: {len(users)}, ролей: {len(roles)}")
        
        with open(shiro_ini_path, 'w', encoding='utf-8') as file:
            # Получаем порядок секций
            section_order = sections.get('_section_order', sections.keys())
            
            for section_name in section_order:
                if section_name == '_section_order':
                    continue
                    
                if section_name == 'users':
                    # Перезаписываем секцию [users] с новыми данными
                    file.write('[users]\n')
                    for user, data in users.items():
                        roles_str = ', '.join(data['roles']) if data['roles'] else ''
                        file.write(f"{user} = {data['password']}{', ' + roles_str if roles_str else ''}\n")
                    file.write('\n')  # Добавляем пустую строку после секции
                    
                elif section_name == 'roles':
                    # Перезаписываем секцию [roles] с новыми данными
                    file.write('[roles]\n')
                    for role, perms in roles.items():
                        file.write(f"{role} = {perms}\n")
                    file.write('\n')  # Добавляем пустую строку после секции
                    
                else:
                    # Сохраняем все остальные секции как есть
                    if section_name in sections:
                        lines = sections[section_name]
                        # Проверяем, нужно ли добавить разделитель
                        if file.tell() > 0 and lines:
                            # Добавляем разделитель между секциями если нужно
                            if not lines[0].startswith('\n') and not lines[0].startswith('['):
                                file.write('\n')
                        
                        file.writelines(lines)
        
        return True
        
    except PermissionError:
        logger.error(f"Нет прав записи в файл {shiro_ini_path}")
        flash('Нет прав записи в файл конфигурации', 'error')
        return False
    except Exception as e:
        logger.error(f"Ошибка записи в файл {shiro_ini_path}: {str(e)}")
        logger.error(f"Тип ошибки: {type(e).__name__}")
        flash(f'Ошибка записи в файл конфигурации: {str(e)}', 'error')
        # Восстанавливаем из резервной копии
        try:
            backup_path = f"{shiro_ini_path}.backup"
            if os.path.exists(backup_path):
                logger.info("Восстанавливаем из резервной копии")
                with open(backup_path, 'r', encoding='utf-8') as src:
                    with open(shiro_ini_path, 'w', encoding='utf-8') as dst:
                        dst.write(src.read())
        except Exception as restore_error:
            logger.error(f"Ошибка восстановления из резервной копии: {str(restore_error)}")
        return False


def check_zeppelin_status():
    """
    Проверяет статус сервиса Zeppelin для разных операционных систем
    
    Returns:
        dict: Словарь с информацией о статусе сервиса
    """
    system_info = get_system_info()
    
    if system_info['demo_mode']:
        # Демо режим для macOS и неподдерживаемых систем
        return {
            'status': 'demo',
            'status_class': 'info',
            'status_text': f'Демо режим ({system_info["os"]})',
            'active': 'demo',
            'enabled': 'N/A',
            'uptime': 'N/A',
            'pid': 'N/A',
            'memory_usage': 'N/A',
            'full_output': f'Демо режим для {system_info["os"]} - {system_info["service_manager"]} недоступен',
            'error': None,
            'os': system_info['os']
        }
    
    try:
        # Проверяем статус сервиса
        status_cmd = system_info['commands']['status']
        result = subprocess.run(
            status_cmd,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Получаем детальную информацию в зависимости от типа управления
        active_status = 'unknown'
        enabled_status = 'unknown'
        status_output = result.stdout
        
        if system_info['zeppelin_type'] == 'systemd':
            # Для systemctl получаем дополнительную информацию
            if 'is_active' in system_info['commands']:
                is_active_result = subprocess.run(
                    system_info['commands']['is_active'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                active_status = is_active_result.stdout.strip()
            
            if 'is_enabled' in system_info['commands']:
                is_enabled_result = subprocess.run(
                    system_info['commands']['is_enabled'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                enabled_status = is_enabled_result.stdout.strip()
            
            # Определяем статус для systemd
            if active_status == 'active':
                status = 'running'
                status_class = 'success'
                status_text = 'Запущен'
            elif active_status == 'inactive':
                status = 'stopped'
                status_class = 'danger'
                status_text = 'Остановлен'
            elif active_status == 'failed':
                status = 'failed'
                status_class = 'danger'
                status_text = 'Ошибка'
            else:
                # Анализируем вывод status
                if 'active (running)' in status_output.lower():
                    status = 'running'
                    status_class = 'success'
                    status_text = 'Запущен'
                elif 'inactive' in status_output.lower() or 'stopped' in status_output.lower():
                    status = 'stopped'
                    status_class = 'danger'
                    status_text = 'Остановлен'
                elif 'failed' in status_output.lower():
                    status = 'failed'
                    status_class = 'danger'
                    status_text = 'Ошибка'
                else:
                    status = 'unknown'
                    status_class = 'warning'
                    status_text = 'Неизвестно'
        
        elif system_info['zeppelin_type'] == 'daemon':
            # Для zeppelin-daemon.sh анализируем вывод
            if result.returncode == 0:
                if 'running' in status_output.lower() or 'started' in status_output.lower():
                    status = 'running'
                    status_class = 'success'
                    status_text = 'Запущен (daemon)'
                    active_status = 'running'
                elif 'stopped' in status_output.lower() or 'not running' in status_output.lower():
                    status = 'stopped'
                    status_class = 'danger'
                    status_text = 'Остановлен (daemon)'
                    active_status = 'stopped'
                else:
                    status = 'unknown'
                    status_class = 'warning'
                    status_text = 'Неизвестно (daemon)'
                    active_status = 'unknown'
            else:
                status = 'error'
                status_class = 'danger'
                status_text = 'Ошибка (daemon)'
                active_status = 'error'
            
            enabled_status = 'manual'  # daemon запускается вручную
        
        else:
            # Fallback анализ
            if 'running' in status_output.lower() or 'active' in status_output.lower():
                status = 'running'
                status_class = 'success'
                status_text = 'Запущен'
            else:
                status = 'stopped'
                status_class = 'danger'
                status_text = 'Остановлен'
        
        # Извлекаем время работы и PID из вывода
        uptime = 'N/A'
        pid = 'N/A'
        memory_usage = 'N/A'
        
        for line in status_output.split('\n'):
            if 'Active:' in line:
                if 'since' in line:
                    uptime = line.split('since')[1].strip()
            elif 'Main PID:' in line:
                pid_match = line.split('Main PID:')[1].strip().split()[0]
                if pid_match.isdigit():
                    pid = pid_match
            elif 'Memory:' in line:
                memory_usage = line.split('Memory:')[1].strip()
        
        return {
            'status': status,
            'status_class': status_class,
            'status_text': status_text,
            'active': active_status,
            'enabled': enabled_status,
            'uptime': uptime,
            'pid': pid,
            'memory_usage': memory_usage,
            'full_output': status_output,
            'error': None,
            'os': system_info['os'],
            'service_manager': system_info['service_manager'],
            'zeppelin_type': system_info['zeppelin_type']
        }
        
    except subprocess.TimeoutExpired:
        logger.error("Таймаут при проверке статуса Zeppelin")
        return {
            'status': 'error',
            'status_class': 'danger',
            'status_text': 'Ошибка проверки',
            'error': 'Таймаут команды',
            'os': system_info['os']
        }
    except FileNotFoundError:
        logger.error(f"Команда {system_info['service_manager']} не найдена")
        return {
            'status': 'error',
            'status_class': 'danger',
            'status_text': 'Ошибка системы',
            'error': f'{system_info["service_manager"]} не найден',
            'os': system_info['os']
        }
    except Exception as e:
        logger.error(f"Ошибка при проверке статуса Zeppelin: {str(e)}")
        return {
            'status': 'error',
            'status_class': 'danger',
            'status_text': 'Ошибка',
            'error': str(e),
            'os': system_info['os']
        }


def execute_service_command(command_type):
    """
    Выполняет команду управления сервисом Zeppelin
    
    Args:
        command_type (str): Тип команды ('start', 'stop', 'restart')
    
    Returns:
        tuple: (success: bool, message: str)
    """
    system_info = get_system_info()
    
    if system_info['demo_mode']:
        logger.info(f"Демо режим: {command_type} Zeppelin на {system_info['os']}")
        time.sleep(2)  # Имитируем работу
        return True, f"Демо режим: команда {command_type} выполнена"
    
    try:
        if command_type == 'restart':
            # Для перезапуска используем специальную команду или stop+start
            if 'restart' in system_info['commands']:
                result = subprocess.run(
                    system_info['commands']['restart'],
                    capture_output=True,
                    text=True,
                    timeout=90
                )
                if result.returncode == 0:
                    service_type = f"({system_info['zeppelin_type']})"
                    return True, f"Сервис успешно перезапущен {service_type}"
                else:
                    error_msg = result.stderr or result.stdout
                    return False, f"Ошибка перезапуска: {error_msg}"
            else:
                # Останавливаем
                result_stop = subprocess.run(
                    system_info['commands']['stop'],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result_stop.returncode != 0:
                    error_msg = result_stop.stderr or result_stop.stdout
                    return False, f"Ошибка остановки: {error_msg}"
                
                # Ждем меньше для daemon
                wait_time = 10 if system_info['zeppelin_type'] == 'daemon' else 30
                time.sleep(wait_time)
                
                # Запускаем
                result_start = subprocess.run(
                    system_info['commands']['start'],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result_start.returncode != 0:
                    error_msg = result_start.stderr or result_start.stdout
                    return False, f"Ошибка запуска: {error_msg}"
                
                service_type = f"({system_info['zeppelin_type']})"
                return True, f"Сервис успешно перезапущен {service_type}"
        
        else:
            # Для start и stop
            if command_type in system_info['commands']:
                logger.info(f"Выполняем команду {command_type}: {' '.join(system_info['commands'][command_type])}")
                
                result = subprocess.run(
                    system_info['commands'][command_type],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                logger.info(f"Результат команды {command_type}: returncode={result.returncode}")
                logger.info(f"stdout: {result.stdout}")
                logger.info(f"stderr: {result.stderr}")
                
                # Для daemon скрипта проверяем результат по-особому
                if system_info['zeppelin_type'] == 'daemon':
                    if command_type == 'start':
                        # Для start команды daemon может возвращать 0 даже если уже запущен
                        # Проверим статус через несколько секунд
                        time.sleep(3)
                        
                        # Проверяем статус после запуска
                        status_result = subprocess.run(
                            system_info['commands']['status'],
                            capture_output=True,
                            text=True,
                            timeout=30
                        )
                        
                        logger.info(f"Проверка статуса после start: {status_result.stdout}")
                        
                        if 'running' in status_result.stdout.lower() or 'started' in status_result.stdout.lower():
                            service_type = f"({system_info['zeppelin_type']})"
                            return True, f"Сервис успешно запущен {service_type}"
                        else:
                            # Попробуем альтернативный способ - через restart
                            logger.info("Обычный start не сработал, пробуем restart")
                            restart_result = subprocess.run(
                                system_info['commands']['restart'],
                                capture_output=True,
                                text=True,
                                timeout=60
                            )
                            
                            if restart_result.returncode == 0:
                                # Проверяем статус еще раз
                                time.sleep(3)
                                final_status = subprocess.run(
                                    system_info['commands']['status'],
                                    capture_output=True,
                                    text=True,
                                    timeout=30
                                )
                                
                                if 'running' in final_status.stdout.lower():
                                    service_type = f"({system_info['zeppelin_type']})"
                                    return True, f"Сервис успешно запущен через restart {service_type}"
                            
                            error_msg = result.stderr or result.stdout or "Не удалось запустить сервис"
                            return False, f"Ошибка запуска daemon: {error_msg}"
                    else:
                        # Для stop и других команд используем стандартную логику
                        if result.returncode == 0:
                            action_text = {'start': 'запущен', 'stop': 'остановлен'}
                            service_type = f"({system_info['zeppelin_type']})"
                            return True, f"Сервис успешно {action_text.get(command_type, command_type)} {service_type}"
                        else:
                            error_msg = result.stderr or result.stdout
                            return False, f"Ошибка {command_type}: {error_msg}"
                else:
                    # Для systemd используем стандартную логику
                    if result.returncode == 0:
                        action_text = {'start': 'запущен', 'stop': 'остановлен'}
                        service_type = f"({system_info['zeppelin_type']})"
                        return True, f"Сервис успешно {action_text.get(command_type, command_type)} {service_type}"
                    else:
                        error_msg = result.stderr or result.stdout
                        return False, f"Ошибка {command_type}: {error_msg}"
            else:
                return False, f"Команда {command_type} не поддерживается на {system_info['os']}"
        
    except subprocess.TimeoutExpired:
        logger.error(f"Таймаут при выполнении команды {command_type}")
        return False, "Таймаут выполнения команды"
    except FileNotFoundError as e:
        logger.error(f"Команда не найдена: {str(e)}")
        if system_info['zeppelin_type'] == 'daemon':
            return False, f"Скрипт zeppelin-daemon.sh не найден: {system_info.get('daemon_path', 'путь неизвестен')}"
        else:
            return False, f"Менеджер сервисов {system_info['service_manager']} не найден"
    except Exception as e:
        logger.error(f"Неожиданная ошибка при {command_type} Zeppelin: {str(e)}")
        return False, f"Неожиданная ошибка: {str(e)}"


def restart_zeppelin():
    """
    Restarts the Zeppelin service.
    
    Returns:
        bool: True if successful, False otherwise
    """
    success, message = execute_service_command('restart')
    if not success:
        logger.error(f"Ошибка перезапуска Zeppelin: {message}")
    return success


@app.route('/')
def login_page():
    """
    Renders the login page.

    Returns:
        str: The rendered HTML of the login page.
    """
    return render_template('login.html')


@app.route('/login', methods=['POST'])
def login():
    """
    Handles the login process by verifying the username and password.

    Returns:
        Response: Redirects to the dashboard if login is successful, otherwise redirects to the login page.
    """
    username = request.form['username']
    password = request.form['password']
    users, _, _ = read_shiro_ini()
    if username in users and users[username]['password'] == password:
        session['username'] = username
        session['last_activity'] = datetime.now().isoformat()
        session.permanent = True
        log_user_action('LOGIN_SUCCESS', username)
        return redirect(url_for('dashboard'))
    else:
        log_user_action('LOGIN_FAILED', username or 'unknown', f'Invalid credentials')
    return redirect(url_for('login_page'))


@app.route('/dashboard')
@login_required
def dashboard():
    """
    Renders the dashboard page if the user is logged in.

    Returns:
        str: The rendered HTML of the dashboard page.
    """
    users, roles, _ = read_shiro_ini()
    zeppelin_status = check_zeppelin_status()
    
    # Фильтруем пользователей для отображения (скрываем пароли защищенных пользователей)
    display_users = {}
    for username, user_roles in {k: v['roles'] for k, v in users.items()}.items():
        if is_protected_user(username):
            display_users[username] = {'roles': user_roles, 'protected': True}
        else:
            display_users[username] = {'roles': user_roles, 'protected': False}
    
    return render_template('dashboard.html', 
                         users=display_users, 
                         roles=roles,
                         zeppelin_status=zeppelin_status,
                         protected_users=PROTECTED_USERS)


@app.route('/logout')
def logout():
    """
    Logs out the user by clearing the session.

    Returns:
        Response: Redirects to the login page.
    """
    username = session.get('username', 'unknown')
    log_user_action('LOGOUT', username)
    session.clear()  # Полная очистка сессии
    flash('Вы успешно вышли из системы', 'success')
    return redirect(url_for('login_page'))


@app.route('/add_user', methods=['POST'])
@login_required
def add_user():
    """
    Adds a new user to the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    new_username = request.form.get('username', '').strip()
    password = request.form.get('password', '').strip()
    current_user = session['username']
    
    # Валидация входных данных
    valid_username, username_msg = validate_input(new_username, 'Имя пользователя', 3, 30)
    if not valid_username:
        flash(username_msg, 'error')
        return redirect(url_for('dashboard'))
    
    valid_password, password_msg = validate_input(password, 'Пароль', 3, 50)
    if not valid_password:
        flash(password_msg, 'error')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if new_username not in users:
        users[new_username] = {'password': password, 'roles': []}
        if write_shiro_ini(users, roles, sections):
            flash(f'Пользователь {new_username} успешно добавлен', 'success')
            log_user_action('ADD_USER', current_user, f'Added user: {new_username}')
        else:
            log_user_action('ADD_USER_FAILED', current_user, f'Failed to write user: {new_username}')
    else:
        flash(f'Пользователь {new_username} уже существует', 'warning')
        log_user_action('ADD_USER_FAILED', current_user, f'User already exists: {new_username}')
    
    return redirect(url_for('dashboard'))


@app.route('/delete_user', methods=['POST'])
@login_required
def delete_user():
    """
    Deletes a user from the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    target_username = request.form.get('username', '').strip()
    current_user = session['username']
    
    if not target_username:
        flash('Не выбран пользователь для удаления', 'error')
        return redirect(url_for('dashboard'))
    
    # Защита от удаления самого себя
    if target_username == current_user:
        flash('Нельзя удалить самого себя', 'error')
        return redirect(url_for('dashboard'))
    
    # Защита от удаления защищенных пользователей
    if is_protected_user(target_username):
        flash(f'Пользователь {target_username} защищен от удаления', 'error')
        log_user_action('DELETE_USER_BLOCKED', current_user, f'Attempted to delete protected user: {target_username}')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if target_username in users:
        del users[target_username]
        if write_shiro_ini(users, roles, sections):
            flash(f'Пользователь {target_username} успешно удален', 'success')
            log_user_action('DELETE_USER', current_user, f'Deleted user: {target_username}')
        else:
            log_user_action('DELETE_USER_FAILED', current_user, f'Failed to delete user: {target_username}')
    else:
        flash(f'Пользователь {target_username} не найден', 'warning')
        log_user_action('DELETE_USER_FAILED', current_user, f'User not found: {target_username}')
    
    return redirect(url_for('dashboard'))


@app.route('/assign_user_role', methods=['POST'])
@login_required
def assign_user_role():
    """
    Assigns a role to a user in the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    target_username = request.form.get('username', '').strip()
    role = request.form.get('role', '').strip()
    current_user = session['username']
    
    if not target_username or not role:
        flash('Не выбран пользователь или роль', 'error')
        return redirect(url_for('dashboard'))
    
    # Защита от изменения ролей защищенных пользователей
    if is_protected_user(target_username):
        flash(f'Роли пользователя {target_username} защищены от изменений', 'error')
        log_user_action('ASSIGN_ROLE_BLOCKED', current_user, f'Attempted to modify protected user: {target_username}')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if target_username in users and role in roles:
        if role not in users[target_username]['roles']:
            users[target_username]['roles'].append(role)
            if write_shiro_ini(users, roles, sections):
                flash(f'Роль "{role}" назначена пользователю "{target_username}"', 'success')
                log_user_action('ASSIGN_ROLE', current_user, f'Assigned role "{role}" to user "{target_username}"')
            else:
                log_user_action('ASSIGN_ROLE_FAILED', current_user, f'Failed to assign role "{role}" to user "{target_username}"')
        else:
            flash(f'Роль "{role}" уже назначена пользователю "{target_username}"', 'warning')
            log_user_action('ASSIGN_ROLE_FAILED', current_user, f'Role "{role}" already assigned to user "{target_username}"')
    else:
        flash('Неверный пользователь или роль', 'error')
        log_user_action('ASSIGN_ROLE_FAILED', current_user, f'Invalid user "{target_username}" or role "{role}"')
    
    return redirect(url_for('dashboard'))


@app.route('/unassign_user_role', methods=['POST'])
@login_required
def unassign_user_role():
    """
    Unassigns a role from a user in the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    target_username = request.form.get('username', '').strip()
    role = request.form.get('role', '').strip()
    current_user = session['username']
    
    if not target_username or not role:
        flash('Не выбран пользователь или роль', 'error')
        return redirect(url_for('dashboard'))
    
    # Защита от изменения ролей защищенных пользователей
    if is_protected_user(target_username):
        flash(f'Роли пользователя {target_username} защищены от изменений', 'error')
        log_user_action('UNASSIGN_ROLE_BLOCKED', current_user, f'Attempted to modify protected user: {target_username}')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if target_username in users and role in users[target_username]['roles']:
        users[target_username]['roles'].remove(role)
        if write_shiro_ini(users, roles, sections):
            flash(f'Роль "{role}" снята с пользователя "{target_username}"', 'success')
            log_user_action('UNASSIGN_ROLE', current_user, f'Removed role "{role}" from user "{target_username}"')
        else:
            log_user_action('UNASSIGN_ROLE_FAILED', current_user, f'Failed to remove role "{role}" from user "{target_username}"')
    else:
        flash(f'Роль "{role}" не найдена у пользователя "{target_username}"', 'warning')
        log_user_action('UNASSIGN_ROLE_FAILED', current_user, f'Role "{role}" not found for user "{target_username}"')
    
    return redirect(url_for('dashboard'))


@app.route('/change_password', methods=['POST'])
@login_required
def change_password():
    """
    Changes password for an existing user in the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    target_username = request.form.get('username', '').strip()
    new_password = request.form.get('new_password', '').strip()
    current_user = session['username']
    
    if not target_username or not new_password:
        flash('Не выбран пользователь или не указан новый пароль', 'error')
        return redirect(url_for('dashboard'))
    
    # Защита от изменения пароля защищенных пользователей
    if is_protected_user(target_username):
        flash(f'Пароль пользователя {target_username} защищен от изменений', 'error')
        log_user_action('CHANGE_PASSWORD_BLOCKED', current_user, f'Attempted to change password for protected user: {target_username}')
        return redirect(url_for('dashboard'))
    
    # Валидация нового пароля
    valid_password, password_msg = validate_input(new_password, 'Новый пароль', 3, 50)
    if not valid_password:
        flash(password_msg, 'error')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if target_username in users:
        old_password = users[target_username]['password']
        users[target_username]['password'] = new_password
        
        if write_shiro_ini(users, roles, sections):
            flash(f'Пароль пользователя {target_username} успешно изменен', 'success')
            log_user_action('CHANGE_PASSWORD', current_user, f'Changed password for user: {target_username}')
        else:
            log_user_action('CHANGE_PASSWORD_FAILED', current_user, f'Failed to change password for user: {target_username}')
    else:
        flash(f'Пользователь {target_username} не найден', 'warning')
        log_user_action('CHANGE_PASSWORD_FAILED', current_user, f'User not found: {target_username}')
    
    return redirect(url_for('dashboard'))


@app.route('/add_role', methods=['POST'])
@login_required
def add_role():
    """
    Adds a new role to the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    role_name = request.form.get('role_name', '').strip()
    current_user = session['username']
    
    # Валидация входных данных
    valid_role, role_msg = validate_input(role_name, 'Название роли', 2, 30)
    if not valid_role:
        flash(role_msg, 'error')
        return redirect(url_for('dashboard'))
    
    users, roles, sections = read_shiro_ini()
    
    if role_name not in roles:
        roles[role_name] = '*'
        if write_shiro_ini(users, roles, sections):
            flash(f'Роль "{role_name}" успешно добавлена', 'success')
            log_user_action('ADD_ROLE', current_user, f'Added role: {role_name}')
        else:
            log_user_action('ADD_ROLE_FAILED', current_user, f'Failed to add role: {role_name}')
    else:
        flash(f'Роль "{role_name}" уже существует', 'warning')
        log_user_action('ADD_ROLE_FAILED', current_user, f'Role already exists: {role_name}')
    
    return redirect(url_for('dashboard'))


@app.route('/check_zeppelin_status')
@login_required
def check_status():
    """
    Проверяет статус сервиса Zeppelin и возвращает JSON
    
    Returns:
        JSON: Статус сервиса Zeppelin
    """
    from flask import jsonify
    
    current_user = session['username']
    log_user_action('CHECK_ZEPPELIN_STATUS', current_user, 'Checked Zeppelin service status')
    
    status = check_zeppelin_status()
    return jsonify(status)


@app.route('/start_zeppelin', methods=['POST'])
@login_required
def start_zeppelin():
    """
    Запускает сервис Zeppelin
    
    Returns:
        Response: Redirects to the dashboard.
    """
    current_user = session['username']
    log_user_action('START_ZEPPELIN', current_user, 'Initiated Zeppelin service start')
    
    success, message = execute_service_command('start')
    
    if success:
        flash(f'Сервис Zeppelin: {message}', 'success')
        log_user_action('START_ZEPPELIN_SUCCESS', current_user, message)
        broadcast_status_change('start', current_user, message)
    else:
        flash(f'Ошибка запуска Zeppelin: {message}', 'error')
        log_user_action('START_ZEPPELIN_FAILED', current_user, message)
        broadcast_status_change('start_failed', current_user, message)
    
    return redirect(url_for('dashboard'))


@app.route('/stop_zeppelin', methods=['POST'])
@login_required
def stop_zeppelin():
    """
    Останавливает сервис Zeppelin
    
    Returns:
        Response: Redirects to the dashboard.
    """
    current_user = session['username']
    log_user_action('STOP_ZEPPELIN', current_user, 'Initiated Zeppelin service stop')
    
    success, message = execute_service_command('stop')
    
    if success:
        flash(f'Сервис Zeppelin: {message}', 'success')
        log_user_action('STOP_ZEPPELIN_SUCCESS', current_user, message)
        broadcast_status_change('stop', current_user, message)
    else:
        flash(f'Ошибка остановки Zeppelin: {message}', 'error')
        log_user_action('STOP_ZEPPELIN_FAILED', current_user, message)
        broadcast_status_change('stop_failed', current_user, message)
    
    return redirect(url_for('dashboard'))


@app.route('/restart_zeppelin', methods=['POST'])
@login_required
def restart():
    """
    Restarts the Zeppelin service.

    Returns:
        Response: Redirects to the dashboard.
    """
    current_user = session['username']
    log_user_action('RESTART_ZEPPELIN', current_user, 'Initiated Zeppelin service restart')
    
    success, message = execute_service_command('restart')
    
    if success:
        flash(f'Сервис Zeppelin: {message}', 'success')
        log_user_action('RESTART_ZEPPELIN_SUCCESS', current_user, message)
        broadcast_status_change('restart', current_user, message)
    else:
        flash(f'Ошибка перезапуска Zeppelin: {message}', 'error')
        log_user_action('RESTART_ZEPPELIN_FAILED', current_user, message)
        broadcast_status_change('restart_failed', current_user, message)
    
    return redirect(url_for('dashboard'))


# WebSocket события
@socketio.on('connect')
def handle_connect():
    """Обработка подключения клиента"""
    if 'username' not in session:
        disconnect()
        return False
    
    logger.info(f"WebSocket подключение: {session['username']} ({request.remote_addr})")
    emit('connected', {'message': f'Добро пожаловать, {session["username"]}!'})

@socketio.on('disconnect')
def handle_disconnect():
    """Обработка отключения клиента"""
    if 'username' in session:
        logger.info(f"WebSocket отключение: {session['username']}")

@socketio.on('request_status_update')
def handle_status_request():
    """Обработка запроса обновления статуса"""
    if 'username' not in session:
        return
    
    try:
        status = check_zeppelin_status()
        emit('status_update', {
            'status': status,
            'timestamp': datetime.now().isoformat(),
            'user': session['username']
        })
    except Exception as e:
        logger.error(f"Ошибка при получении статуса для WebSocket: {e}")
        emit('error', {'message': 'Ошибка при получении статуса'})

def broadcast_status_change(action, user, details=None):
    """Рассылка изменений статуса всем подключенным клиентам"""
    try:
        status = check_zeppelin_status()
        socketio.emit('status_change', {
            'action': action,
            'user': user,
            'details': details,
            'status': status,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Ошибка при рассылке статуса: {e}")

def broadcast_user_change(action, username, user_data=None):
    """Рассылка изменений пользователей всем подключенным клиентам"""
    try:
        socketio.emit('user_change', {
            'action': action,
            'username': username,
            'user_data': user_data,
            'timestamp': datetime.now().isoformat(),
            'total_users': len(users)
        })
    except Exception as e:
        logger.error(f"Ошибка при рассылке изменений пользователей: {e}")

# Автоматическое обновление статуса каждые 30 секунд
def auto_status_broadcast():
    """Автоматическая рассылка статуса каждые 30 секунд"""
    while True:
        try:
            time.sleep(30)
            # Используем функцию check_zeppelin_status
            with app.app_context():
                status = check_zeppelin_status()
                socketio.emit('auto_status_update', {
                    'status': status,
                    'timestamp': datetime.now().isoformat()
                })
        except Exception as e:
            logger.error(f"Ошибка автоматического обновления статуса: {e}")

# Запускаем фоновый поток для автообновлений
status_thread = threading.Thread(target=auto_status_broadcast, daemon=True)
status_thread.start()

if __name__ == '__main__':
    """
    Runs the Flask application.
    """
    socketio.run(app, host='0.0.0.0', port=5003, debug=False, allow_unsafe_werkzeug=True)