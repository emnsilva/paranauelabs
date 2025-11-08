from flask import Flask, jsonify, request
import psycopg2
import os
from psycopg2.extras import RealDictCursor

# Cria a aplicação Flask - nossa base do xerife
app = Flask(__name__)

# MUDAMOS: Conexão com PostgreSQL via variável de ambiente
def get_db_connection():
    """
    Abre uma nova conexão com o PostgreSQL.
    """
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        database_url = "postgresql://investigador:acme@postgres:5432/outlaws"
    
    conn = psycopg2.connect(database_url)
    # Configura para retornar linhas como dicionários
    conn.cursor_factory = RealDictCursor
    return conn

@app.get('/outlaws')
def get_outlaws():
    """Lista todos os bandidos."""
    conn = get_db_connection()
    try:
        # MUDAMOS: Sintaxe PostgreSQL - %s em vez de ?
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM outlaws ORDER BY id')
        outlaws = cursor.fetchall()
        return jsonify([dict(row) for row in outlaws])
    except Exception as e:
        return jsonify({'error': f'Erro ao buscar bandidos: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

@app.post('/outlaws')
def create_outlaw():
    """Adiciona um novo bandido."""
    try:
        data = request.get_json(force=True)
    except:
        return jsonify({'error': 'JSON inválido'}), 400

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        # MUDAMOS: Sintaxe PostgreSQL - %s e RETURNING
        cursor.execute(
            'INSERT INTO outlaws (name, reward, crime) VALUES (%s, %s, %s) RETURNING *',
            (data['name'], data['reward'], data['crime'])
        )
        new_outlaw = cursor.fetchone()
        conn.commit()
        return jsonify(dict(new_outlaw)), 201
    except Exception as e:
        conn.rollback()
        return jsonify({'error': f'Erro ao criar bandido: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

@app.get('/outlaws/<int:id>')
def get_outlaw(id):
    """Busca um bandido específico pelo ID."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        # MUDAMOS: Sintaxe PostgreSQL - %s
        cursor.execute('SELECT * FROM outlaws WHERE id = %s', (id,))
        outlaw = cursor.fetchone()
        if not outlaw:
            return jsonify({'error': 'Bandido não encontrado'}), 404
        return jsonify(dict(outlaw))
    except Exception as e:
        return jsonify({'error': f'Erro ao buscar bandido: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

@app.put('/outlaws/<int:id>')
def update_outlaw(id):
    """Atualiza os dados de um bandido."""
    try:
        data = request.get_json(force=True)
    except:
        return jsonify({'error': 'JSON inválido'}), 400

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        # MUDAMOS: Sintaxe PostgreSQL - %s
        cursor.execute(
            'UPDATE outlaws SET name=%s, reward=%s, crime=%s WHERE id=%s',
            (data['name'], data['reward'], data['crime'], id)
        )
        
        if cursor.rowcount == 0:
            return jsonify({'error': 'Bandido não encontrado'}), 404
        
        conn.commit()
        return jsonify({'message': 'Bandido atualizado com sucesso!'})
    except Exception as e:
        conn.rollback()
        return jsonify({'error': f'Erro ao atualizar bandido: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

@app.delete('/outlaws/<int:id>')
def delete_outlaw(id):
    """Remove um bandido da lista."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        # MUDAMOS: Sintaxe PostgreSQL - %s
        cursor.execute('DELETE FROM outlaws WHERE id = %s', (id,))
        
        if cursor.rowcount == 0:
            return jsonify({'error': 'Bandido não encontrado'}), 404
        
        conn.commit()
        return jsonify({'message': 'Bandido deletado com sucesso!'})
    except Exception as e:
        conn.rollback()
        return jsonify({'error': f'Erro ao deletar bandido: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    # Inicia o servidor Flask
    # host='0.0.0.0' permite conexões de qualquer IP na rede
    # port=5000 usa a porta 5000
    app.run(host='0.0.0.0', port=5000)