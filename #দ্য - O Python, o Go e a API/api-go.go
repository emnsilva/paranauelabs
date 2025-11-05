package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	// Importamos o driver do sqlite3. O _ significa que só precisamos dos seus efeitos colaterais (registrar-se).
	_ "github.com/mattn/go-sqlite3"
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

// Server encapsula as dependências da aplicação, como o banco de dados e o roteador.
type Server struct {
	db     *sql.DB
	router *mux.Router
}

// Função principal - ponto de entrada da aplicação
func main() {
	// Conecta ao banco de dados SQLite
	db, err := sql.Open("sqlite3", "./outlaws.db")
	if err != nil {
		log.Fatalf("❌ Não foi possível conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	// Cria uma nova instância do nosso servidor, injetando o banco de dados.
	server := &Server{
		db:     db,
		router: mux.NewRouter(),
	}

	// Configura as rotas
	server.setupRoutes()

	log.Println("🚀 Servidor Go rodando na porta 8080...")
	// Inicia o servidor HTTP na porta 8080
	// log.Fatal para se ocorrer erro, o programa para com mensagem
	log.Fatal(http.ListenAndServe(":8080", server.router))
}

// setupRoutes configura todas as rotas da API.
func (s *Server) setupRoutes() {
	s.router.HandleFunc("/outlaws", s.getOutlaws).Methods("GET")
	s.router.HandleFunc("/outlaws", s.createOutlaw).Methods("POST")
	s.router.HandleFunc("/outlaws/{id}", s.getOutlaw).Methods("GET")
	s.router.HandleFunc("/outlaws/{id}", s.updateOutlaw).Methods("PUT")
	s.router.HandleFunc("/outlaws/{id}", s.deleteOutlaw).Methods("DELETE")
}

// getOutlaws - Manipula requisições GET para /outlaws
// Lista TODOS os bandidos cadastrados no banco
func (s *Server) getOutlaws(w http.ResponseWriter, r *http.Request) {
	// Executa query SQL para buscar todos os registros da tabela outlaws
	rows, err := s.db.Query("SELECT * FROM outlaws ORDER BY id")
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao buscar bandidos"})
		return
	}
	defer rows.Close()

	// Slice (lista dinâmica) para armazenar os bandidos
	var outlaws []Outlaw

	// Percorre cada linha do resultado da query
	for rows.Next() {
		var o Outlaw
		// Scan copia os valores da linha atual para a struct Outlaw
		if err := rows.Scan(&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt); err != nil {
			respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao ler dados do bandido"})
			return
		}
		outlaws = append(outlaws, o)
	}

	respondWithJSON(w, http.StatusOK, outlaws)
}

// getOutlaw - Manipula requisições GET para /outlaws/{id}
// Busca um bandido específico pelo ID na URL
func (s *Server) getOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai o parâmetro {id} da URL e converte para inteiro
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	var o Outlaw

	// QueryRow busca APENAS UMA linha no banco
	// Scan copia os valores diretamente para a struct
	err = s.db.QueryRow("SELECT * FROM outlaws WHERE id = ?", id).Scan(
		&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		} else {
			respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao buscar bandido"})
		}
		return
	}

	respondWithJSON(w, http.StatusOK, o)
}

// createOutlaw - Manipula requisições POST para /outlaws
// Adiciona um novo bandido ao banco de dados
func (s *Server) createOutlaw(w http.ResponseWriter, r *http.Request) {
	var o Outlaw
	// Decodifica o JSON do corpo da requisição para a struct Outlaw
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "JSON inválido"})
		return
	}

	// Executa INSERT no banco (name, reward, crime)
	// created_at é preenchido automaticamente pelo banco
	result, err := s.db.Exec(
		"INSERT INTO outlaws (name, reward, crime) VALUES (?, ?, ?)",
		o.Name, o.Reward, o.Crime)
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao criar bandido"})
		return
	}

	// Pega o ID que foi gerado automaticamente pelo banco
	id, err := result.LastInsertId()
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao obter ID do novo bandido"})
		return
	}
	o.ID = int(id)

	// Para obter o `created_at`, precisamos buscar o registro recém-criado.
	err = s.db.QueryRow("SELECT created_at FROM outlaws WHERE id = ?", o.ID).Scan(&o.CreatedAt)
	if err != nil {
		// Mesmo que a criação tenha funcionado, retornamos o que temos com um aviso.
		// Em um cenário real, a transação poderia ser revertida.
		log.Printf("Aviso: não foi possível obter created_at para o novo bandido ID %d: %v", o.ID, err)
	}

	respondWithJSON(w, http.StatusCreated, o)
}

// updateOutlaw - Manipula requisições PUT para /outlaws/{id}
// Atualiza os dados de um bandido existente
func (s *Server) updateOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai ID da URL
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	var o Outlaw
	// Decodifica JSON do corpo da requisição
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "JSON inválido"})
		return
	}

	// Executa UPDATE no banco - modifica name, reward e crime
	result, err := s.db.Exec(
		"UPDATE outlaws SET name=?, reward=?, crime=? WHERE id=?",
		o.Name, o.Reward, o.Crime, id)
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao atualizar bandido"})
		return
	}

	// Verifica quantas linhas foram afetadas pelo UPDATE
	rows, err := result.RowsAffected()
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao verificar atualização"})
		return
	}

	// Se nenhuma linha foi afetada, bandido não existe
	if rows == 0 {
		respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]string{"message": "Bandido atualizado com sucesso!"})
}

// deleteOutlaw - Manipula requisições DELETE para /outlaws/{id}
// Remove um bandido do banco de dados
func (s *Server) deleteOutlaw(w http.ResponseWriter, r *http.Request) {
	// Extrai ID da URL
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	// Executa DELETE no banco
	result, err := s.db.Exec("DELETE FROM outlaws WHERE id = ?", id)
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao deletar bandido"})
		return
	}

	// Verifica se alguma linha foi deletada
	rows, err := result.RowsAffected()
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao verificar deleção"})
		return
	}

	// Se nenhuma linha afetada, bandido não existia
	if rows == 0 {
		respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]string{"message": "Bandido deletado com sucesso!"})
}

// --- Funções Auxiliares (Helpers) ---

// respondWithJSON envia uma resposta padronizada em JSON.
func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if payload != nil {
		json.NewEncoder(w).Encode(payload)
	}
}