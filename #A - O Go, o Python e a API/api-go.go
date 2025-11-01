package main

import (
	"database/sql"           // Para operações com banco de dados
	"encoding/json"          // Para codificar/decodificar JSON
	"log"                    // Para logging no console
	"net/http"               // Para criar servidor HTTP
	"strconv"                // Para converter string para inteiro
	
	"github.com/gorilla/mux"        // Roteador para gerenciar URLs de forma inteligente
)

// Outlaw define a estrutura de dados de um bandido
// As tags `json:"xxx"` definem como os campos serão nomeados no JSON
type Outlaw struct {
	ID        int     `json:"id"`         // ID único do bandido (chave primária)
	Name      string  `json:"name"`       // Nome do bandido procurado
	Reward    float64 `json:"reward"`     // Valor da recompensa em dólares
	Crime     string  `json:"crime"`      // Crime pelo qual é procurado
	CreatedAt string  `json:"created_at"` // Data de registro no sistema
}

// Variável global para acesso ao banco de dados em todas as funções
var db *sql.DB

// Função principal - ponto de entrada da aplicação
func main() {
	// Conecta ao banco de dados SQLite
	db, _ = sql.Open("sqlite3", "./outlaws.db")
	// defer = executa este comando quando a função main terminar
	// Garante que a conexão com o banco será fechada corretamente
	defer db.Close()
	
	// Cria um roteador para gerenciar as rotas da API
	r := mux.NewRouter()
	
	// Configura todas as rotas da API:
	// Cada rota associa um URL + método HTTP a uma função específica
	
	// Rota para listar todos os bandidos (GET /outlaws)
	r.HandleFunc("/outlaws", getOutlaws).Methods("GET")
	
	// Rota para criar novo bandido (POST /outlaws)  
	r.HandleFunc("/outlaws", createOutlaw).Methods("POST")
	
	// Rota para buscar um bandido específico (GET /outlaws/1)
	r.HandleFunc("/outlaws/{id}", getOutlaw).Methods("GET")
	
	// Rota para atualizar um bandido (PUT /outlaws/1)
	r.HandleFunc("/outlaws/{id}", updateOutlaw).Methods("PUT")
	
	// Rota para deletar um bandido (DELETE /outlaws/1)
	r.HandleFunc("/outlaws/{id}", deleteOutlaw).Methods("DELETE")
	
	log.Println("🚀 Servidor Go rodando na porta 8080...")
	// Inicia o servidor HTTP na porta 8080
	// log.Fatal para se ocorrer erro, o programa para com mensagem
	log.Fatal(http.ListenAndServe(":8080", r))
}

// getOutlaws - Manipula requisições GET para /outlaws
// Lista TODOS os bandidos cadastrados no banco
func getOutlaws(w http.ResponseWriter, r *http.Request) {
	// Executa query SQL para buscar todos os registros da tabela outlaws
	rows, _ := db.Query("SELECT * FROM outlaws")
	// Garante que o resultado da query será fechado ao final da função
	defer rows.Close()
	
	// Slice (lista dinâmica) para armazenar os bandidos
	var outlaws []Outlaw
	
	// Percorre cada linha do resultado da query
	for rows.Next() {
		var o Outlaw
		// Scan copia os valores da linha atual para a struct Outlaw
		// &o.ID = passa o endereço da variável para Scan poder modificar
		rows.Scan(&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)
		// Adiciona o bandido à lista
		outlaws = append(outlaws, o)
	}
	
	// Define o tipo de conteúdo da resposta como JSON
	w.Header().Set("Content-Type", "application/json")
	// Converte a lista de bandidos para JSON e envia como resposta
	json.NewEncoder(w).Encode(outlaws)
}

// getOutlaw - Manipula requisições GET para /outlaws/{id}
// Busca um bandido específico pelo ID na URL
func getOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai o parâmetro {id} da URL e converte para inteiro
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	var o Outlaw
	
	// QueryRow busca APENAS UMA linha no banco
	// Scan copia os valores diretamente para a struct
	err := db.QueryRow("SELECT * FROM outlaws WHERE id = ?", id).Scan(
		&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)
	
	// Se erro (bandido não encontrado), retorna 404
	if err != nil {
		http.Error(w, "Bandido não encontrado", 404)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(o)
}

// createOutlaw - Manipula requisições POST para /outlaws
// Adiciona um novo bandido ao banco de dados
func createOutlaw(w http.ResponseWriter, r *http.Request) {
	var o Outlaw
	// Decodifica o JSON do corpo da requisição para a struct Outlaw
	json.NewDecoder(r.Body).Decode(&o)
	
	// Executa INSERT no banco (name, reward, crime)
	// created_at é preenchido automaticamente pelo banco
	result, _ := db.Exec(
		"INSERT INTO outlaws (name, reward, crime) VALUES (?, ?, ?)",
		o.Name, o.Reward, o.Crime)
	
	// Pega o ID que foi gerado automaticamente pelo banco
	id, _ := result.LastInsertId()
	o.ID = int(id)
	
	// Define status HTTP 201 (Created) - recurso criado com sucesso
	w.WriteHeader(201)
	w.Header().Set("Content-Type", "application/json")
	// Retorna o bandido criado, incluindo o novo ID
	json.NewEncoder(w).Encode(o)
}

// updateOutlaw - Manipula requisições PUT para /outlaws/{id}
// Atualiza os dados de um bandido existente
func updateOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai ID da URL
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	var o Outlaw
	// Decodifica JSON do corpo da requisição
	json.NewDecoder(r.Body).Decode(&o)
	
	// Executa UPDATE no banco - modifica name, reward e crime
	result, _ := db.Exec(
		"UPDATE outlaws SET name=?, reward=?, crime=? WHERE id=?",
		o.Name, o.Reward, o.Crime, id)
	
	// Verifica quantas linhas foram afetadas pelo UPDATE
	rows, _ := result.RowsAffected()
	// Se nenhuma linha foi afetada, bandido não existe
	if rows == 0 {
		http.Error(w, "Bandido não encontrado", 404)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Atualizado!"})
}

// deleteOutlaw - Manipula requisições DELETE para /outlaws/{id}
// Remove um bandido do banco de dados
func deleteOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai ID da URL
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	
	// Executa DELETE no banco
	result, _ := db.Exec("DELETE FROM outlaws WHERE id = ?", id)
	// Verifica se alguma linha foi deletada
	rows, _ := result.RowsAffected()
	
	// Se nenhuma linha afetada, bandido não existia
	if rows == 0 {
		http.Error(w, "Bandido não encontrado", 404)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Deletado!"})
}