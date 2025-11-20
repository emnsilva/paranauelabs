from flask import Flask, jsonify, request
from flasgger import Swagger
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Configuração SIMPLES do Swagger
app.config['SWAGGER'] = {
    'title': 'Wanted API - Python',
    'uiversion': 3
}
swagger = Swagger(app)

# Configuração do banco a partir do .env
def get_db_connection():
    # Usa DATABASE_URL do .env ou valores padrão para Docker
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        # Formato: postgresql://user:password@host:port/database
        conn = psycopg2.connect(database_url)
    else:
        # Fallback para valores do docker-compose
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'db'),
            database=os.getenv('DB_NAME', 'wanted'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', 'postgres'),
            port=os.getenv('DB_PORT', '5432')
        )
    
    conn.cursor_factory = RealDictCursor
    return conn

# Health Check
@app.route('/health', methods=['GET'])
def health_check():
    """
    Health Check da API
    ---
    tags:
      - Sistema
    responses:
      200:
        description: Status da API e banco de dados
    """
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"})
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

# GET /v1/outlaws - Listar todos os bandidos
@app.route('/v1/outlaws', methods=['GET'])
def get_outlaws():
    """
    Listar todos os bandidos
    ---
    tags:
      - Bandidos
    responses:
      200:
        description: Lista de bandidos recuperada com sucesso
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM outlaws ORDER BY id')
        outlaws = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "data": outlaws,
            "count": len(outlaws)
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# GET /v1/outlaws/<id> - Buscar bandido por ID
@app.route('/v1/outlaws/<int:id>', methods=['GET'])
def get_outlaw(id):
    """
    Buscar bandido por ID
    ---
    tags:
      - Bandidos
    parameters:
      - name: id
        in: path
        type: integer
        required: true
    responses:
      200:
        description: Bandido encontrado
      404:
        description: Bandido não encontrado
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM outlaws WHERE id = %s', (id,))
        outlaw = cur.fetchone()
        cur.close()
        conn.close()
        
        if not outlaw:
            return jsonify({"success": False, "error": "Bandido não encontrado"}), 404
            
        return jsonify({
            "success": True,
            "data": outlaw
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# POST /v1/outlaws - Criar novo bandido
@app.route('/v1/outlaws', methods=['POST'])
def create_outlaw():
    """
    Criar novo bandido
    ---
    tags:
      - Bandidos
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - name
            - reward
            - crime
          properties:
            name:
              type: string
            reward:
              type: number
            crime:
              type: string
    responses:
      201:
        description: Bandido criado com sucesso
      400:
        description: Dados inválidos
    """
    try:
        data = request.get_json()
        
        if not data or not all(k in data for k in ['name', 'reward', 'crime']):
            return jsonify({
                "success": False, 
                "error": "Campos obrigatórios: name, reward, crime"
            }), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO outlaws (name, reward, crime) VALUES (%s, %s, %s) RETURNING *',
            (data['name'], data['reward'], data['crime'])
        )
        new_outlaw = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "message": "Bandido criado com sucesso",
            "data": new_outlaw
        }), 201
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# PUT /v1/outlaws/<id> - Atualizar bandido
@app.route('/v1/outlaws/<int:id>', methods=['PUT'])
def update_outlaw(id):
    """
    Atualizar bandido
    ---
    tags:
      - Bandidos
    parameters:
      - name: id
        in: path
        type: integer
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            name:
              type: string
            reward:
              type: number
            crime:
              type: string
    responses:
      200:
        description: Bandido atualizado com sucesso
      404:
        description: Bandido não encontrado
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"success": False, "error": "Dados JSON necessários"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Verifica se existe
        cur.execute('SELECT * FROM outlaws WHERE id = %s', (id,))
        if not cur.fetchone():
            cur.close()
            conn.close()
            return jsonify({"success": False, "error": "Bandido não encontrado"}), 404
        
        # Atualiza
        cur.execute(
            'UPDATE outlaws SET name = %s, reward = %s, crime = %s WHERE id = %s RETURNING *',
            (data.get('name'), data.get('reward'), data.get('crime'), id)
        )
        updated_outlaw = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "message": "Bandido atualizado com sucesso",
            "data": updated_outlaw
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# DELETE /v1/outlaws/<id> - Deletar bandido
@app.route('/v1/outlaws/<int:id>', methods=['DELETE'])
def delete_outlaw(id):
    """
    Deletar bandido
    ---
    tags:
      - Bandidos
    parameters:
      - name: id
        in: path
        type: integer
        required: true
    responses:
      200:
        description: Bandido deletado com sucesso
      404:
        description: Bandido não encontrado
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute('DELETE FROM outlaws WHERE id = %s RETURNING *', (id,))
        deleted_outlaw = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        if not deleted_outlaw:
            return jsonify({"success": False, "error": "Bandido não encontrado"}), 404
            
        return jsonify({
            "success": True,
            "message": "Bandido deletado com sucesso",
            "data": deleted_outlaw
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('PYTHON_API_PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)