from flask import Flask, render_template, request, redirect, url_for, session
import os
import time
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your_secret_key'
shiro_ini_path = 'shiro.ini'

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

    Returns:
        tuple: A tuple containing three dictionaries:
            - users (dict): A dictionary of users with their passwords and roles.
            - roles (dict): A dictionary of roles with their permissions.
            - sections (dict): A dictionary of sections with their lines.
    """
    users = {}
    roles = {}
    sections = {}
    current_section = None

    with open(shiro_ini_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    for line in lines:
        stripped_line = line.strip()

        if stripped_line.startswith('[') and stripped_line.endswith(']'):
            current_section = stripped_line[1:-1]
            sections[current_section] = []

        if current_section:
            sections[current_section].append(line)

        if current_section == 'users':
            parts = stripped_line.split('=')
            if len(parts) == 2:
                username, data = parts[0].strip(), parts[1].strip()
                data_parts = [part.strip() for part in data.split(',') if part.strip()]
                if data_parts:
                    users[username] = {'password': data_parts[0], 'roles': data_parts[1:]}
        elif current_section == 'roles':
            parts = stripped_line.split('=')
            if len(parts) == 2:
                role = parts[0].strip()
                roles[role] = parts[1].strip()

    return users, roles, sections


def write_shiro_ini(users, roles, sections):
    """
    Writes the users, roles, and sections back to the shiro.ini file.

    Args:
        users (dict): A dictionary of users with their passwords and roles.
        roles (dict): A dictionary of roles with their permissions.
        sections (dict): A dictionary of sections with their lines.
    """
    with open(shiro_ini_path, 'w', encoding='utf-8') as file:
        for section, lines in sections.items():
            if section == 'users':
                file.write('[users]\n')
                for user, data in users.items():
                    roles_str = ', '.join(data['roles']) if data['roles'] else ''
                    file.write(f"{user} = {data['password']}{', ' + roles_str if roles_str else ''}\n")
            elif section == 'roles':
                file.write('[roles]\n')
                for role, perms in roles.items():
                    file.write(f"{role} = {perms}\n")
            else:
                if not file.tell() == 0:
                    file.write('\n')
                file.writelines(lines)


def restart_zeppelin():
    """
    Restarts the Zeppelin service by stopping it, waiting for 30 seconds, and then starting it again.
    """
    os.system('sudo systemctl stop zeppelin')
    time.sleep(30)
    os.system('sudo systemctl start zeppelin')


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
        log_user_action('LOGIN_SUCCESS', username)
        return redirect(url_for('dashboard'))
    else:
        log_user_action('LOGIN_FAILED', username or 'unknown', f'Invalid credentials')
    return redirect(url_for('login_page'))


@app.route('/dashboard')
def dashboard():
    """
    Renders the dashboard page if the user is logged in.

    Returns:
        str: The rendered HTML of the dashboard page.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    users, roles, _ = read_shiro_ini()
    return render_template('dashboard.html', users={k: v['roles'] for k, v in users.items()}, roles=roles)


@app.route('/logout')
def logout():
    """
    Logs out the user by clearing the session.

    Returns:
        Response: Redirects to the login page.
    """
    username = session.get('username', 'unknown')
    log_user_action('LOGOUT', username)
    session.pop('username', None)
    return redirect(url_for('login_page'))


@app.route('/add_user', methods=['POST'])
def add_user():
    """
    Adds a new user to the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    new_username = request.form['username']
    password = request.form['password']
    current_user = session['username']
    users, roles, sections = read_shiro_ini()
    if new_username not in users:
        users[new_username] = {'password': password, 'roles': []}
        write_shiro_ini(users, roles, sections)
        log_user_action('ADD_USER', current_user, f'Added user: {new_username}')
    else:
        log_user_action('ADD_USER_FAILED', current_user, f'User already exists: {new_username}')
    return redirect(url_for('dashboard'))


@app.route('/delete_user', methods=['POST'])
def delete_user():
    """
    Deletes a user from the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    target_username = request.form['username']
    current_user = session['username']
    users, roles, sections = read_shiro_ini()
    if target_username in users:
        del users[target_username]
        write_shiro_ini(users, roles, sections)
        log_user_action('DELETE_USER', current_user, f'Deleted user: {target_username}')
    else:
        log_user_action('DELETE_USER_FAILED', current_user, f'User not found: {target_username}')
    return redirect(url_for('dashboard'))


@app.route('/assign_user_role', methods=['POST'])
def assign_user_role():
    """
    Assigns a role to a user in the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    target_username = request.form['username']
    role = request.form['role']
    current_user = session['username']
    users, roles, sections = read_shiro_ini()
    if target_username in users and role in roles:
        if role not in users[target_username]['roles']:
            users[target_username]['roles'].append(role)
            write_shiro_ini(users, roles, sections)
            log_user_action('ASSIGN_ROLE', current_user, f'Assigned role "{role}" to user "{target_username}"')
        else:
            log_user_action('ASSIGN_ROLE_FAILED', current_user, f'Role "{role}" already assigned to user "{target_username}"')
    else:
        log_user_action('ASSIGN_ROLE_FAILED', current_user, f'Invalid user "{target_username}" or role "{role}"')
    return redirect(url_for('dashboard'))


@app.route('/unassign_user_role', methods=['POST'])
def unassign_user_role():
    """
    Unassigns a role from a user in the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    target_username = request.form['username']
    role = request.form['role']
    current_user = session['username']
    users, roles, sections = read_shiro_ini()
    if target_username in users and role in users[target_username]['roles']:
        users[target_username]['roles'].remove(role)
        write_shiro_ini(users, roles, sections)
        log_user_action('UNASSIGN_ROLE', current_user, f'Removed role "{role}" from user "{target_username}"')
    else:
        log_user_action('UNASSIGN_ROLE_FAILED', current_user, f'Role "{role}" not found for user "{target_username}"')
    return redirect(url_for('dashboard'))


@app.route('/add_role', methods=['POST'])
def add_role():
    """
    Adds a new role to the shiro.ini file.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    role_name = request.form['role_name']
    current_user = session['username']
    users, roles, sections = read_shiro_ini()
    if role_name not in roles:
        roles[role_name] = '*'
        write_shiro_ini(users, roles, sections)
        log_user_action('ADD_ROLE', current_user, f'Added role: {role_name}')
    else:
        log_user_action('ADD_ROLE_FAILED', current_user, f'Role already exists: {role_name}')
    return redirect(url_for('dashboard'))


@app.route('/restart_zeppelin', methods=['POST'])
def restart():
    """
    Restarts the Zeppelin service.

    Returns:
        Response: Redirects to the dashboard.
    """
    if 'username' not in session:
        return redirect(url_for('login_page'))
    current_user = session['username']
    log_user_action('RESTART_ZEPPELIN', current_user, 'Initiated Zeppelin service restart')
    try:
        restart_zeppelin()
        log_user_action('RESTART_ZEPPELIN_SUCCESS', current_user, 'Zeppelin service restarted successfully')
    except Exception as e:
        log_user_action('RESTART_ZEPPELIN_FAILED', current_user, f'Failed to restart Zeppelin: {str(e)}')
    return redirect(url_for('dashboard'))


if __name__ == '__main__':
    """
    Runs the Flask application.
    """
    app.run(host='0.0.0.0', port=5000, debug=False)