from flask import Flask, jsonify, request, g
import sqlite3

# Cria a aplicação Flask - nossa base do xerife
app = Flask(__name__)
DB_PATH = 'outlaws.db'

def get_db():
    """
    Abre uma nova conexão com o banco de dados se não houver uma no contexto da requisição atual.
    Isso garante que a mesma conexão seja reutilizada durante toda a requisição.
    """
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH)
        # Configura para retornar linhas como dicionários (acesso por nome da coluna)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    """
    Fecha a conexão com o banco de dados ao final da requisição.
    """
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

@app.get('/outlaws')
def get_outlaws():
    """Lista todos os bandidos."""
    db = get_db()
    outlaws = db.execute('SELECT * FROM outlaws ORDER BY id').fetchall()
    return jsonify([dict(row) for row in outlaws])

@app.post('/outlaws')
def create_outlaw():
    """Adiciona um novo bandido."""
    try:
        data = request.get_json(force=True)
    except:
        return jsonify({'error': 'JSON inválido'}), 400

    db = get_db()
    with db: # 'with' gerencia commit/rollback automaticamente
        cursor = db.execute(
            'INSERT INTO outlaws (name, reward, crime) VALUES (?, ?, ?)',
            (data['name'], data['reward'], data['crime'])
        )
    
    # Busca o bandido recém-criado para retornar o objeto completo
    new_outlaw = db.execute('SELECT * FROM outlaws WHERE id = ?', (cursor.lastrowid,)).fetchone()
    return jsonify(dict(new_outlaw)), 201

@app.get('/outlaws/<int:id>')
def get_outlaw(id):
    """Busca um bandido específico pelo ID."""
    db = get_db()
    outlaw = db.execute('SELECT * FROM outlaws WHERE id = ?', (id,)).fetchone()
    if not outlaw:
        return jsonify({'error': 'Bandido não encontrado'}), 404
    return jsonify(dict(outlaw))

@app.put('/outlaws/<int:id>')
def update_outlaw(id):
    """Atualiza os dados de um bandido."""
    try:
        data = request.get_json(force=True)
    except:
        return jsonify({'error': 'JSON inválido'}), 400

    db = get_db()
    with db:
        cursor = db.execute(
            'UPDATE outlaws SET name=?, reward=?, crime=? WHERE id=?',
            (data['name'], data['reward'], data['crime'], id)
        )
    
    if cursor.rowcount == 0:
        return jsonify({'error': 'Bandido não encontrado'}), 404
    
    return jsonify({'message': 'Bandido atualizado com sucesso!'})

@app.delete('/outlaws/<int:id>')
def delete_outlaw(id):
    """Remove um bandido da lista."""
    db = get_db()
    with db:
        cursor = db.execute('DELETE FROM outlaws WHERE id = ?', (id,))
    
    if cursor.rowcount == 0:
        return jsonify({'error': 'Bandido não encontrado'}), 404
    
    return jsonify({'message': 'Bandido deletado com sucesso!'})

if __name__ == '__main__':
    # Inicia o servidor Flask
    # host='0.0.0.0' permite conexões de qualquer IP na rede
    # port=5000 usa a porta 5000
    app.run(host='0.0.0.0', port=5000)