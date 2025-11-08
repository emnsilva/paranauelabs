package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

// Outlaw define a estrutura de dados de um bandido
type Outlaw struct {
	ID        int     `json:"id"`
	Name      string  `json:"name"`
	Reward    float64 `json:"reward"`
	Crime     string  `json:"crime"`
	CreatedAt string  `json:"created_at"`
}

// Server encapsula as dependências da aplicação
type Server struct {
	db     *sql.DB
	router *mux.Router
}

// Função principal - ponto de entrada da aplicação
func main() {
	// Conexão com PostgreSQL via variável de ambiente
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgresql://investigador:acme@postgres:5432/outlaws?sslmode=disable"
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("❌ Não foi possível conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	// Testa a conexão
	if err := db.Ping(); err != nil {
		log.Fatalf("❌ Não foi possível comunicar com o banco: %v", err)
	}

	log.Println("✅ Conectado ao PostgreSQL!")

	server := &Server{
		db:     db,
		router: mux.NewRouter(),
	}

	server.setupRoutes()

	log.Println("🚀 Servidor Go rodando na porta 8080...")
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

// getOutlaws - Lista TODOS os bandidos
func (s *Server) getOutlaws(w http.ResponseWriter, r *http.Request) {
	rows, err := s.db.Query("SELECT id, name, reward, crime, created_at FROM outlaws ORDER BY id")
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao buscar bandidos: " + err.Error()})
		return
	}
	defer rows.Close()

	var outlaws []Outlaw

	for rows.Next() {
		var o Outlaw
		if err := rows.Scan(&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt); err != nil {
			respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao ler dados do bandido: " + err.Error()})
			return
		}
		outlaws = append(outlaws, o)
	}

	respondWithJSON(w, http.StatusOK, outlaws)
}

// getOutlaw - Busca um bandido específico pelo ID
func (s *Server) getOutlaw(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	var o Outlaw

	err = s.db.QueryRow("SELECT id, name, reward, crime, created_at FROM outlaws WHERE id = $1", id).Scan(
		&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		} else {
			respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao buscar bandido: " + err.Error()})
		}
		return
	}

	respondWithJSON(w, http.StatusOK, o)
}

// createOutlaw - Adiciona um novo bandido
func (s *Server) createOutlaw(w http.ResponseWriter, r *http.Request) {
	var o Outlaw
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "JSON inválido"})
		return
	}

	var id int
	var createdAt string
	err := s.db.QueryRow(
		"INSERT INTO outlaws (name, reward, crime) VALUES ($1, $2, $3) RETURNING id, created_at",
		o.Name, o.Reward, o.Crime).Scan(&id, &createdAt)
		
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao criar bandido: " + err.Error()})
		return
	}

	o.ID = id
	o.CreatedAt = createdAt

	respondWithJSON(w, http.StatusCreated, o)
}

// updateOutlaw - Atualiza um bandido existente
func (s *Server) updateOutlaw(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	var o Outlaw
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "JSON inválido"})
		return
	}

	result, err := s.db.Exec(
		"UPDATE outlaws SET name=$1, reward=$2, crime=$3 WHERE id=$4",
		o.Name, o.Reward, o.Crime, id)
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao atualizar bandido: " + err.Error()})
		return
	}

	rows, err := result.RowsAffected()
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao verificar atualização: " + err.Error()})
		return
	}

	if rows == 0 {
		respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]string{"message": "Bandido atualizado com sucesso!"})
}

// deleteOutlaw - Remove um bandido
func (s *Server) deleteOutlaw(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"error": "ID inválido"})
		return
	}

	result, err := s.db.Exec("DELETE FROM outlaws WHERE id = $1", id)
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao deletar bandido: " + err.Error()})
		return
	}

	rows, err := result.RowsAffected()
	if err != nil {
		respondWithJSON(w, http.StatusInternalServerError, map[string]string{"error": "Erro ao verificar deleção: " + err.Error()})
		return
	}

	if rows == 0 {
		respondWithJSON(w, http.StatusNotFound, map[string]string{"error": "Bandido não encontrado"})
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]string{"message": "Bandido deletado com sucesso!"})
}

// respondWithJSON envia uma resposta padronizada em JSON.
func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if payload != nil {
		json.NewEncoder(w).Encode(payload)
	}
}