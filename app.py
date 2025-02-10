from flask import Flask, render_template, request, redirect, url_for
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
import configparser
import os
import subprocess

app = Flask(__name__)
app.secret_key = 'supersecretkey'
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

SHIRO_FILE = 'shiro.ini'
ZEPPELIN_SERVICE = 'zeppelin'


class User(UserMixin):
    def __init__(self, username):
        self.id = username


@login_manager.user_loader
def load_user(user_id):
    return User(user_id)


def load_shiro_config():
    config = configparser.ConfigParser(allow_no_value=True)
    config.read(SHIRO_FILE)
    return config


def save_shiro_config(config):
    with open(SHIRO_FILE, 'w') as configfile:
        config.write(configfile)


def restart_zeppelin():
    subprocess.run(['sudo', 'systemctl', 'restart', ZEPPELIN_SERVICE], check=True)


@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        config = load_shiro_config()

        if config.has_section('users') and username in config['users'] and config['users'][username] == password:
            user = User(username)
            login_user(user)
            return redirect(url_for('dashboard'))

    return render_template('login.html')


@app.route('/dashboard')
@login_required
def dashboard():
    config = load_shiro_config()
    users = dict(config.items('users')) if config.has_section('users') else {}
    groups = dict(config.items('groups')) if config.has_section('groups') else {}
    user_roles = dict(config.items('roles')) if config.has_section('roles') else {}
    return render_template('dashboard.html', users=users, groups=groups, user_roles=user_roles)


@app.route('/add_user', methods=['POST'])
@login_required
def add_user():
    username = request.form['username']
    password = request.form['password']
    config = load_shiro_config()
    if not config.has_section('users'):
        config.add_section('users')
    config.set('users', username, password)
    save_shiro_config(config)
    return redirect(url_for('dashboard'))


@app.route('/delete_user', methods=['POST'])
@login_required
def delete_user():
    username = request.form['username']
    config = load_shiro_config()
    if config.has_section('users'):
        config.remove_option('users', username)
    if config.has_section('roles'):
        config.remove_option('roles', username)
    save_shiro_config(config)
    return redirect(url_for('dashboard'))


@app.route('/add_group', methods=['POST'])
@login_required
def add_group():
    groupname = request.form['groupname']
    config = load_shiro_config()
    if not config.has_section('groups'):
        config.add_section('groups')
    config.set('groups', groupname, '')
    save_shiro_config(config)
    return redirect(url_for('dashboard'))


@app.route('/delete_group', methods=['POST'])
@login_required
def delete_group():
    groupname = request.form['groupname']
    config = load_shiro_config()
    if config.has_section('groups'):
        config.remove_option('groups', groupname)
    save_shiro_config(config)
    return redirect(url_for('dashboard'))


@app.route('/assign_user_group', methods=['POST'])
@login_required
def assign_user_group():
    username = request.form['username']
    groupname = request.form['groupname']
    config = load_shiro_config()
    if not config.has_section('roles'):
        config.add_section('roles')
    config.set('roles', username, groupname)
    save_shiro_config(config)
    return redirect(url_for('dashboard'))


@app.route('/restart_zeppelin', methods=['POST'])
@login_required
def restart_service():
    restart_zeppelin()
    return redirect(url_for('dashboard'))


@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=True)
