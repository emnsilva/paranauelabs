# Importa módulos HTTP e .env
from flask import Flask, jsonify, request, url_for
import psycopg2, os
from functools import wraps
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
from flasgger import Swagger, swag_from
from marshmallow import Schema, fields, validate, ValidationError
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
from datetime import datetime

# Carrega as variáveis do arquivo .env
load_dotenv()

app = Flask(__name__)
swagger = Swagger(app)

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Rate Limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://"  # Usa storage em memória para simplificar
)

# Schemas de validação com Marshmallow
class OutlawSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=1, max=100))
    reward = fields.Float(required=True, validate=validate.Range(min=0))
    crime = fields.Str(required=True, validate=validate.Length(min=1, max=200))

class OutlawUpdateSchema(Schema):
    name = fields.Str(validate=validate.Length(min=1, max=100))
    reward = fields.Float(validate=validate.Range(min=0))
    crime = fields.Str(validate=validate.Length(min=1, max=200))

# Instâncias dos schemas
outlaw_schema = OutlawSchema()
outlaw_update_schema = OutlawUpdateSchema()

# Função para obter variáveis de ambiente com valores padrão
def get_env_variable(key, default=None):
    value = os.getenv(key, default)
    if not value and default is None:
        raise Exception(f"Variável de ambiente {key} não configurada")
    return value

# Configuração centralizada
class Config:
    DB_URL = get_env_variable('DATABASE_URL', 'postgresql://postgres:postgres@db:5432/wanted')
    PORT = int(get_env_variable('PYTHON_API_PORT', '5000'))
    DEBUG = get_env_variable('FLASK_DEBUG', 'False').lower() == 'true'

# Conexão com PostgreSQL via variável de ambiente
def get_db_connection():
    database_url = Config.DB_URL
    
    conn = psycopg2.connect(database_url)
    conn.cursor_factory = RealDictCursor
    return conn

# Repository Pattern para operações de banco
class OutlawRepository:
    def __init__(self, cursor):
        self.cursor = cursor
    
    def find_all(self):
        self.cursor.execute('SELECT * FROM outlaws ORDER BY id')
        return self.cursor.fetchall()
    
    def find_by_id(self, id):
        self.cursor.execute('SELECT * FROM outlaws WHERE id = %s', (id,))
        return self.cursor.fetchone()
    
    def create(self, name, reward, crime):
        self.cursor.execute(
            'INSERT INTO outlaws (name, reward, crime) VALUES (%s, %s, %s) RETURNING *',
            (name, reward, crime)
        )
        return self.cursor.fetchone()
    
    def update(self, id, name, reward, crime):
        self.cursor.execute(
            'UPDATE outlaws SET name=%s, reward=%s, crime=%s WHERE id=%s',
            (name, reward, crime, id)
        )
        return self.cursor.rowcount
    
    def delete(self, id):
        self.cursor.execute('DELETE FROM outlaws WHERE id = %s', (id,))
        return self.cursor.rowcount

# Refatorando a função generate_links para evitar repetição
def generate_links(outlaw_id=None):
    base_links = {
        'self': url_for('get_outlaws', _external=True) if not outlaw_id else url_for('get_outlaw', id=outlaw_id, _external=True),
        'collection': url_for('get_outlaws', _external=True)
    }
    
    if not outlaw_id:
        base_links['create'] = url_for('create_outlaw', _external=True)
        return base_links
    
    base_links.update({
        'update': url_for('update_outlaw', id=outlaw_id, _external=True),
        'delete': url_for('delete_outlaw', id=outlaw_id, _external=True)
    })
    return base_links

# Decorador para gerenciar a conexão com o banco de dados
def with_db_connection(needs_json=False, validate_schema=None):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if needs_json:
                try:
                    data = request.get_json(force=True)
                    if validate_schema:
                        try:
                            validated_data = validate_schema.load(data)
                            kwargs['validated_data'] = validated_data
                        except ValidationError as err:
                            return jsonify({
                                'success': False, 
                                'error': 'Dados inválidos', 
                                'details': err.messages
                            }), 400
                    else:
                        kwargs['data'] = data
                except:
                    return jsonify({'success': False, 'error': 'JSON inválido'}), 400

            conn = get_db_connection()
            cursor = conn.cursor()
            try:
                # Injeta o repositório no kwargs
                kwargs['repository'] = OutlawRepository(cursor)
                result = f(cursor, *args, **kwargs)
                conn.commit()
                return result
            except Exception as e:
                conn.rollback()
                logger.error(f"Erro no banco de dados: {str(e)}")
                raise
            finally:
                cursor.close()
                conn.close()
        return decorated_function
    return decorator

# Handlers de erro específicos
@app.errorhandler(psycopg2.Error)
def handle_db_error(e):
    logger.error(f"Erro de banco de dados: {str(e)}")
    return jsonify({
        'success': False, 
        'error': 'Erro interno no servidor (banco de dados)'
    }), 500

@app.errorhandler(ValidationError)
def handle_validation_error(e):
    return jsonify({
        'success': False, 
        'error': 'Dados de entrada inválidos',
        'details': e.messages
    }), 400

# Manipulador de erro global
@app.errorhandler(Exception)
def handle_exception(e):
    # Evita capturar exceções HTTP padrão (como 404)
    from werkzeug.exceptions import HTTPException
    if isinstance(e, HTTPException):
        return e
    
    logger.error(f"Erro interno não tratado: {str(e)}")
    return jsonify({
        'success': False, 
        'error': 'Erro interno no servidor'
    }), 500

# Health Check Endpoint
@app.get('/health')
def health_check():
    # Testa a conexão com o banco
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        conn.close()
        db_status = 'healthy'
    except Exception as e:
        logger.error(f"Health check falhou: {str(e)}")
        db_status = 'unhealthy'

    return jsonify({
        'status': 'healthy',
        'database': db_status,
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })

# GET - Lista os bandidos
@app.get('/v1/outlaws')
@with_db_connection()
@swag_from('swagger/get_outlaws.yml')
@limiter.limit("100 per minute")
def get_outlaws(cursor, repository):
    outlaws = repository.find_all()
    
    outlaws_with_links = []
    for outlaw in outlaws:
        outlaw_dict = dict(outlaw)
        outlaw_dict['_links'] = generate_links(outlaw_dict['id'])
        outlaws_with_links.append(outlaw_dict)
    
    logger.info(f"Listados {len(outlaws)} bandidos")
    
    response = jsonify({
        'success': True,
        'data': outlaws_with_links,
        'count': len(outlaws),
        '_links': generate_links()
    })
    response.headers['Cache-Control'] = 'public, max-age=300'
    return response

# GET - Busca um bandido específico pelo ID
@app.get('/v1/outlaws/<int:id>')
@with_db_connection()
@swag_from('swagger/get_outlaw.yml')
@limiter.limit("100 per minute")
def get_outlaw(cursor, id, repository):
    outlaw = repository.find_by_id(id)
    if not outlaw:
        logger.warning(f"Bandido não encontrado: ID {id}")
        return jsonify({'success': False, 'error': 'Bandido não encontrado'}), 404
    
    outlaw_dict = dict(outlaw)
    outlaw_dict['_links'] = generate_links(id)
    
    return jsonify({
        'success': True,
        'data': outlaw_dict,
        '_links': generate_links(id)
    })

# POST - Adiciona um novo bandido
@app.post('/v1/outlaws')
@with_db_connection(needs_json=True, validate_schema=outlaw_schema)
@swag_from('swagger/create_outlaw.yml')
@limiter.limit("10 per minute")
def create_outlaw(cursor, validated_data, repository):
    try:
        new_outlaw = repository.create(
            validated_data['name'],
            validated_data['reward'],
            validated_data['crime']
        )
        
        outlaw_dict = dict(new_outlaw)
        outlaw_dict['_links'] = generate_links(outlaw_dict['id'])
        
        logger.info(f"Bandido criado: {validated_data['name']} (ID: {outlaw_dict['id']})")
        
        return jsonify({
            'success': True,
            'message': 'Bandido criado com sucesso',
            'data': outlaw_dict,
            '_links': generate_links(outlaw_dict['id'])
        }), 201
        
    except Exception as e:
        logger.error(f"Erro ao criar bandido: {str(e)}")
        raise

# PUT - Atualiza informação de um bandido
@app.put('/v1/outlaws/<int:id>')
@with_db_connection(needs_json=True, validate_schema=outlaw_update_schema)
@swag_from('swagger/update_outlaw.yml')
@limiter.limit("20 per minute")
def update_outlaw(cursor, id, validated_data, repository):
    # Verifica se o bandido existe
    existing_outlaw = repository.find_by_id(id)
    if not existing_outlaw:
        logger.warning(f"Tentativa de atualizar bandido não encontrado: ID {id}")
        return jsonify({'success': False, 'error': 'Bandido não encontrado'}), 404
    
    # Atualiza apenas os campos fornecidos
    update_data = {
        'name': validated_data.get('name', existing_outlaw['name']),
        'reward': validated_data.get('reward', existing_outlaw['reward']),
        'crime': validated_data.get('crime', existing_outlaw['crime'])
    }
    
    rows_affected = repository.update(
        id,
        update_data['name'],
        update_data['reward'],
        update_data['crime']
    )
    
    logger.info(f"Bandido atualizado: ID {id}")
    
    return jsonify({
        'success': True,
        'message': 'Bandido atualizado com sucesso',
        '_links': generate_links(id)
    })

# DELETE - Remove um bandido
@app.delete('/v1/outlaws/<int:id>')
@with_db_connection()
@swag_from('swagger/delete_outlaw.yml')
@limiter.limit("10 per minute")
def delete_outlaw(cursor, id, repository):
    rows_affected = repository.delete(id)
    if rows_affected == 0:
        logger.warning(f"Tentativa de deletar bandido não encontrado: ID {id}")
        return jsonify({'success': False, 'error': 'Bandido não encontrado'}), 404
    
    logger.info(f"Bandido deletado: ID {id}")
    
    return jsonify({
        'success': True,
        'message': 'Bandido deletado com sucesso',
        '_links': {
            'collection': url_for('get_outlaws', _external=True),
            'create': url_for('create_outlaw', _external=True)
        }
    })

# Inicia o servidor Flask
if __name__ == '__main__':
    logger.info(f"Iniciando servidor na porta {Config.PORT}")
    app.run(
        host='0.0.0.0', 
        port=Config.PORT, 
        debug=Config.DEBUG
    )