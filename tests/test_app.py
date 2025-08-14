import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_login_page(client):
    """Ensure the login page loads properly."""
    response = client.get('/')
    assert response.status_code == 200
    assert b"Invalid Credentials" not in response.data  # Page should load without error

def test_valid_login(client):
    """Test login with valid credentials."""
    response = client.post('/', data={"username": "admin", "password": "password123"}, follow_redirects=True)
    assert response.status_code == 200
    assert b"Welcome" in response.data  # Should redirect to welcome page

def test_invalid_login(client):
    """Test login with incorrect credentials."""
    response = client.post('/', data={"username": "wrong", "password": "wrong"}, follow_redirects=True)
    assert response.status_code == 200
    assert b"Invalid Credentials" in response.data  # Should show error message

