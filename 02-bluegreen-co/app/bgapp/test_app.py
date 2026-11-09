import pytest
from bgapp import create_app

@pytest.fixture
def client():
    app = create_app()
    app.config.update({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:" # Usa SQLite em memória para testar rápido
    })
    with app.test_client() as client:
        yield client

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'alive'

def test_version(client):
    response = client.get('/version')
    assert response.status_code == 200
    assert 'color' in response.json
    assert 'version' in response.json

def test_degrade_off(client):
    response = client.get('/debug/degrade')
    assert response.status_code == 200