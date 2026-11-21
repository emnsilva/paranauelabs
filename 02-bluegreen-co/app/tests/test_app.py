import pytest
from bgapp import create_app

class TestConfig:
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    APP_COLOR = "blue"
    APP_VERSION = "v1"
    APP_FAIL_MODE = False

@pytest.fixture
def client():
    app = create_app(TestConfig)
    with app.test_client() as client:
        yield client

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'alive'

def test_version(client):
    response = client.get('/version')
    assert response.status_code == 200
    assert response.json['color'] == 'blue'
    assert response.json['version'] == 'v1'

def test_degrade_off(client):
    response = client.get('/debug/degrade')
    assert response.status_code == 200
    assert response.json['status'] == 'ok'