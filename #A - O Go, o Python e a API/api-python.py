from flask import Flask, jsonify, request
import sqlite3

# Cria a aplicação Flask - nossa base do xerife
app = Flask(__name__)

@app.route('/outlaws', methods=['GET', 'POST'])
def handle_outlaws():
    """
    Rota para gerenciar a lista completa de procurados.
    GET: Retorna todos os bandidos
    POST: Adiciona um novo bandido à lista
    """
    # Conecta ao banco de dados - abre o cofre
    conn = sqlite3.connect('outlaws.db')
    # Configura para retornar linhas como dicionários (acesso por nome da coluna)
    conn.row_factory = sqlite3.Row
    
    # SE FOR UMA REQUISIÇÃO GET - LISTAR TODOS OS BANDIDOS
    if request.method == 'GET':
        # Executa query para buscar todos os bandidos
        outlaws = conn.execute('SELECT * FROM outlaws').fetchall()
        # Fecha a conexão com o banco
        conn.close()
        # Converte cada linha para dicionário e retorna como JSON
        return jsonify([dict(row) for row in outlaws])
    
    # SE FOR UMA REQUISIÇÃO POST - ADICIONAR NOVO BANDIDO
    if request.method == 'POST':
        # Pega os dados JSON do corpo da requisição
        data = request.get_json()
        # Cria um cursor para executar comandos SQL
        cursor = conn.cursor()
        # Insere novo bandido no banco de dados
        cursor.execute(
            'INSERT INTO outlaws (name, reward, crime) VALUES (?, ?, ?)',
            (data['name'], data['reward'], data['crime'])
        )
        # Salva as mudanças no banco
        conn.commit()
        # Fecha a conexão
        conn.close()
        # Retorna o ID do novo bandido criado com status 201 (Created)
        return jsonify({'id': cursor.lastrowid}), 201

@app.route('/outlaws/<int:id>', methods=['GET', 'PUT', 'DELETE'])
def handle_outlaw(id):
    """
    Rota para gerenciar um bandido específico pelo ID.
    GET: Busca um bandido pelo ID
    PUT: Atualiza os dados de um bandido
    DELETE: Remove um bandido da lista
    """
    # Conecta ao banco de dados
    conn = sqlite3.connect('outlaws.db')
    conn.row_factory = sqlite3.Row
    # Cria cursor para executar comandos
    cursor = conn.cursor()
    
    # SE FOR GET - BUSCAR BANDIDO ESPECÍFICO
    if request.method == 'GET':
        # Busca o bandido com o ID especificado
        outlaw = cursor.execute('SELECT * FROM outlaws WHERE id = ?', (id,)).fetchone()
        # Fecha a conexão
        conn.close()
        # Se encontrou, retorna como JSON; se não, retorna 404 (Não encontrado)
        return jsonify(dict(outlaw)) if outlaw else ('', 404)
    
    # SE FOR PUT - ATUALIZAR BANDIDO
    if request.method == 'PUT':
        # Pega os novos dados do corpo da requisição
        data = request.get_json()
        # Atualiza TODOS os campos do bandido no banco
        cursor.execute(
            'UPDATE outlaws SET name=?, reward=?, crime=? WHERE id=?',
            (data['name'], data['reward'], data['crime'], id)
        )
        # Salva as mudanças
        conn.commit()
        # Fecha a conexão
        conn.close()
        # Se atualizou alguma linha, retorna sucesso; se não, retorna 404
        return jsonify({'message': 'Atualizado'}) if cursor.rowcount > 0 else ('', 404)
    
    # SE FOR DELETE - REMOVER BANDIDO
    if request.method == 'DELETE':
        # Remove o bandido do banco de dados
        cursor.execute('DELETE FROM outlaws WHERE id = ?', (id,))
        # Salva as mudanças
        conn.commit()
        # Fecha a conexão
        conn.close()
        # Se removeu alguma linha, retorna sucesso; se não, retorna 404
        return jsonify({'message': 'Deletado'}) if cursor.rowcount > 0 else ('', 404)

if __name__ == '__main__':
    # Inicia o servidor Flask
    # host='0.0.0.0' permite conexões de qualquer IP na rede
    # port=5000 usa a porta 5000
    app.run(host='0.0.0.0', port=5000)