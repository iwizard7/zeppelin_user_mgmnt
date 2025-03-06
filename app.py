from flask import Flask, render_template, request, redirect, url_for, session
import os

app = Flask(__name__)
app.secret_key = 'your_secret_key'
shiro_ini_path = 'shiro.ini'


def read_shiro_ini():
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
    os.system('sudo systemctl restart zeppelin')


@app.route('/')
def login_page():
    return render_template('login.html')


@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    users, _, _ = read_shiro_ini()
    if username in users and users[username]['password'] == password:
        session['username'] = username
        return redirect(url_for('dashboard'))
    return redirect(url_for('login_page'))


@app.route('/dashboard')
def dashboard():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    users, roles, _ = read_shiro_ini()
    return render_template('dashboard.html', users={k: v['roles'] for k, v in users.items()}, roles=roles)


@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login_page'))


@app.route('/add_user', methods=['POST'])
def add_user():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    username = request.form['username']
    password = request.form['password']
    users, roles, sections = read_shiro_ini()
    if username not in users:
        users[username] = {'password': password, 'roles': []}
        write_shiro_ini(users, roles, sections)
    return redirect(url_for('dashboard'))


@app.route('/delete_user', methods=['POST'])
def delete_user():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    username = request.form['username']
    users, roles, sections = read_shiro_ini()
    if username in users:
        del users[username]
        write_shiro_ini(users, roles, sections)
    return redirect(url_for('dashboard'))


@app.route('/assign_user_role', methods=['POST'])
def assign_user_role():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    username = request.form['username']
    role = request.form['role']
    users, roles, sections = read_shiro_ini()
    if username in users and role in roles:
        if role not in users[username]['roles']:
            users[username]['roles'].append(role)
            write_shiro_ini(users, roles, sections)
    return redirect(url_for('dashboard'))


@app.route('/unassign_user_role', methods=['POST'])
def unassign_user_role():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    username = request.form['username']
    role = request.form['role']
    users, roles, sections = read_shiro_ini()
    if username in users and role in users[username]['roles']:
        users[username]['roles'].remove(role)
        write_shiro_ini(users, roles, sections)
    return redirect(url_for('dashboard'))


@app.route('/add_role', methods=['POST'])
def add_role():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    role_name = request.form['role_name']
    users, roles, sections = read_shiro_ini()
    if role_name not in roles:
        roles[role_name] = '*'
        write_shiro_ini(users, roles, sections)
    return redirect(url_for('dashboard'))


@app.route('/restart_zeppelin', methods=['POST'])
def restart():
    if 'username' not in session:
        return redirect(url_for('login_page'))
    restart_zeppelin()
    return redirect(url_for('dashboard'))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
