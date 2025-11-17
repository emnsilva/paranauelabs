# Importa módulos HTTP e .env
from flask import Flask, jsonify, request, url_for
import psycopg2, os
from functools import wraps
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Carrega as variáveis do arquivo .env
load_dotenv()

app = Flask(__name__)

# Conexão com PostgreSQL via variável de ambiente
def get_db_connection():
    database_url = os.getenv('DB_PYTHON_URL')
    if not database_url:
        raise Exception("DB_PYTHON_URL não configurada no ambiente")
    
    conn = psycopg2.connect(database_url)
    conn.cursor_factory = RealDictCursor
    return conn

# Helper para gerar links HATEOAS
def generate_links(outlaw_id=None):
    base_links = {
        'self': url_for('get_outlaws', _external=True) if not outlaw_id else url_for('get_outlaw', id=outlaw_id, _external=True),
        'collection': url_for('get_outlaws', _external=True)
    }
    
    if outlaw_id:
        base_links.update({
            'update': url_for('update_outlaw', id=outlaw_id, _external=True),
            'delete': url_for('delete_outlaw', id=outlaw_id, _external=True)
        })
    else:
        base_links['create'] = url_for('create_outlaw', _external=True)
    
    return base_links

# Decorador para gerenciar a conexão com o banco de dados
def with_db_connection(needs_json=False):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if needs_json:
                try:
                    data = request.get_json(force=True)
                    kwargs['data'] = data
                except:
                    return jsonify({'success': False, 'error': 'JSON inválido'}), 400

            conn = get_db_connection()
            cursor = conn.cursor()
            try:
                result = f(cursor, *args, **kwargs)
                conn.commit()
                return result
            except Exception:
                conn.rollback()
                raise # Re-lança a exceção para o errorhandler do Flask
            finally:
                cursor.close()
                conn.close()
        return decorated_function
    return decorator

# Manipulador de erro global
@app.errorhandler(Exception)
def handle_exception(e):
    # Evita capturar exceções HTTP padrão (como 404)
    from werkzeug.exceptions import HTTPException
    if isinstance(e, HTTPException):
        return e
    return jsonify(success=False, error=f"Erro interno no servidor: {str(e)}"), 500

# GET - Lista os bandidos
@app.get('/v1/outlaws')
@with_db_connection()
def get_outlaws(cursor):
    cursor.execute('SELECT * FROM outlaws ORDER BY id')
    outlaws = cursor.fetchall()
    
    outlaws_with_links = []
    for outlaw in outlaws:
        outlaw_dict = dict(outlaw)
        outlaw_dict['_links'] = generate_links(outlaw_dict['id'])
        outlaws_with_links.append(outlaw_dict)
    
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
def get_outlaw(cursor, id):
    cursor.execute('SELECT * FROM outlaws WHERE id = %s', (id,))
    outlaw = cursor.fetchone()
    if not outlaw:
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
@with_db_connection(needs_json=True)
def create_outlaw(cursor, data):
    cursor.execute(
        'INSERT INTO outlaws (name, reward, crime) VALUES (%s, %s, %s) RETURNING *',
        (data['name'], data['reward'], data['crime'])
    )
    new_outlaw = cursor.fetchone()
    outlaw_dict = dict(new_outlaw)
    outlaw_dict['_links'] = generate_links(outlaw_dict['id'])
    
    return jsonify({
        'success': True,
        'message': 'Bandido criado com sucesso',
        'data': outlaw_dict,
        '_links': generate_links(outlaw_dict['id'])
    }), 201

# PUT - Atualiza informação de um bandido
@app.put('/v1/outlaws/<int:id>')
@with_db_connection(needs_json=True)
def update_outlaw(cursor, id, data):
    cursor.execute(
        'UPDATE outlaws SET name=%s, reward=%s, crime=%s WHERE id=%s',
        (data['name'], data['reward'], data['crime'], id)
    )
    if cursor.rowcount == 0:
        return jsonify({'success': False, 'error': 'Bandido não encontrado'}), 404
    
    return jsonify({
        'success': True,
        'message': 'Bandido atualizado com sucesso',
        '_links': generate_links(id)
    })

# DELETE - Remove um bandido
@app.delete('/v1/outlaws/<int:id>')
@with_db_connection()
def delete_outlaw(cursor, id):
    cursor.execute('DELETE FROM outlaws WHERE id = %s', (id,))
    if cursor.rowcount == 0:
        return jsonify({'success': False, 'error': 'Bandido não encontrado'}), 404
    
    return jsonify({
        'success': True,
        'message': 'Bandido deletado com sucesso',
        '_links': {
            'collection': url_for('get_outlaws', _external=True),
            'create': url_for('create_outlaw', _external=True)
        }
    })

# Inicia o servidor Flask usando a porta 5000
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)