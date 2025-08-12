import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SECRET_KEY'] = 'test-secret-key'
    with app.test_client() as client:
        yield client

def test_login_page(client):
    """Test login page loads"""
    rv = client.get('/')
    assert rv.status_code == 200
    assert b'Login' in rv.data
    assert b'Username' in rv.data
    assert b'Password' in rv.data

def test_login_success(client):
    """Test successful login"""
    rv = client.post('/login', data={
        'username': 'admin',
        'password': 'admin123'
    }, follow_redirects=True)
    assert rv.status_code == 200

def test_login_failure(client):
    """Test failed login"""
    rv = client.post('/login', data={
        'username': 'wrong',
        'password': 'wrong'
    })
    assert rv.status_code == 302  # Redirect back to login

def test_dashboard_access_without_login(client):
    """Test dashboard requires login"""
    rv = client.get('/dashboard')
    assert rv.status_code == 302  # Redirect to login

def test_dashboard_with_login(client):
    """Test dashboard loads after login"""
    # Сначала логинимся
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    rv = client.get('/dashboard')
    assert rv.status_code == 200
    assert b'Zeppelin User Management' in rv.data
    assert b'Dashboard' in rv.data

def test_logout(client):
    """Test logout functionality"""
    # Логинимся
    with client.session_transaction() as sess:
        sess['username'] = 'admin'
    
    # Выходим
    rv = client.get('/logout')
    assert rv.status_code == 302  # Redirect to login
    
    # Проверяем что сессия очищена
    rv = client.get('/dashboard')
    assert rv.status_code == 302  # Should redirect to login

def test_static_files(client):
    """Test static files are accessible"""
    rv = client.get('/static/themes.css')
    assert rv.status_code == 200
    assert b'--bg-color' in rv.data  # CSS variable from themes.css

def test_zeppelin_status_endpoint(client):
    """Test Zeppelin status endpoint requires login"""
    rv = client.get('/check_zeppelin_status')
    assert rv.status_code == 302  # Redirect to login

def test_protected_routes_require_login(client):
    """Test that protected routes redirect to login"""
    protected_routes = [
        '/dashboard',
        '/add_user',
        '/delete_user',
        '/add_role',
        '/assign_user_role',
        '/unassign_user_role',
        '/change_password',
        '/start_zeppelin',
        '/stop_zeppelin',
        '/restart_zeppelin',
        '/check_zeppelin_status'
    ]
    
    for route in protected_routes:
        rv = client.get(route) if route == '/dashboard' or route == '/check_zeppelin_status' else client.post(route)
        assert rv.status_code == 302, f"Route {route} should redirect to login"