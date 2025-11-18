package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

// Estrutura do bandido - igual ao banco de dados
type Outlaw struct {
	ID        int               `json:"id"`
	Name      string            `json:"name"`
	Reward    float64           `json:"reward"`
	Crime     string            `json:"crime"`
	CreatedAt string            `json:"created_at,omitempty"`
	Links     map[string]string `json:"_links,omitempty"`
}

// Resposta padrão para todas as APIs
type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
	Error   string      `json:"error,omitempty"`
	Count   int         `json:"count,omitempty"`
	Links   interface{} `json:"_links,omitempty"`
}

var db *sql.DB

func main() {
	// Conecta com o PostgreSQL com retry
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgresql://acme:@cM3_2025!@postgres:5432/outlaws?sslmode=disable"
	}

	var err error
	maxAttempts := 5
	
	for i := 1; i <= maxAttempts; i++ {
		db, err = sql.Open("postgres", dbURL)
		if err != nil {
			log.Printf("⚠️ Tentativa %d: Erro ao abrir conexão: %v", i, err)
			time.Sleep(3 * time.Second)
			continue
		}

		err = db.Ping()
		if err != nil {
			log.Printf("⚠️ Tentativa %d: Banco não responde: %v", i, err)
			db.Close()
			time.Sleep(3 * time.Second)
			continue
		}
		
		break
	}

	if err != nil {
		log.Fatal("❌ Não foi possível conectar ao PostgreSQL após várias tentativas")
	}
	defer db.Close()

	log.Println("✅ Conectado ao PostgreSQL!")

	// Configura as rotas
	r := mux.NewRouter()
	
	// Rotas da API - iguais à API Python
	r.HandleFunc("/v1/outlaws", getOutlaws).Methods("GET")
	r.HandleFunc("/v1/outlaws/{id}", getOutlaw).Methods("GET")
	r.HandleFunc("/v1/outlaws", createOutlaw).Methods("POST")
	r.HandleFunc("/v1/outlaws/{id}", updateOutlaw).Methods("PUT")
	r.HandleFunc("/v1/outlaws/{id}", deleteOutlaw).Methods("DELETE")

	// Swagger simples - redireciona para Swagger UI online
	r.HandleFunc("/swagger", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "https://petstore.swagger.io/?url=http://localhost:8080/swagger/get_outlaws.yml", http.StatusSeeOther)
	})

	// Serve arquivos YAML do Swagger
	r.PathPrefix("/swagger/").Handler(http.StripPrefix("/swagger/", http.FileServer(http.Dir("./swagger"))))

	log.Println("🚀 API Go rodando na porta 8080")
	log.Println("📚 Swagger em http://localhost:8080/swagger")
	log.Fatal(http.ListenAndServe(":8080", r))
}

// sendResponse envia uma resposta JSON formatada
func sendResponse(w http.ResponseWriter, code int, success bool, data interface{}, message string, links interface{}) {
	response := Response{
		Success: success,
		Data:    data,
		Message: message,
		Links:   links,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(response)
}

// sendError envia uma resposta de erro JSON padronizada
func sendError(w http.ResponseWriter, message string, code int) {	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(Response{Success: false, Error: message})
}	

// GET /v1/outlaws - Lista todos os bandidos
func getOutlaws(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM outlaws ORDER BY id")
	if err != nil {
		sendError(w, "Erro ao buscar bandidos: "+err.Error(), 500)
		return
	}
	defer rows.Close()

	var outlaws []Outlaw
	for rows.Next() {
		var o Outlaw
		err := rows.Scan(&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)
		if err != nil {
			sendError(w, "Erro ao ler dados: "+err.Error(), 500)
			return
		}		
		o.Links = generateLinks(o.ID)
		outlaws = append(outlaws, o)
	}

	sendResponse(w, 200, true, outlaws, "", generateLinks(0))
}

// GET /v1/outlaws/{id} - Busca um bandido por ID
func getOutlaw(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	var o Outlaw

	err := db.QueryRow("SELECT * FROM outlaws WHERE id = $1", id).Scan(
		&o.ID, &o.Name, &o.Reward, &o.Crime, &o.CreatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			sendError(w, "Bandido não encontrado", 404)
		} else {
			sendError(w, "Erro ao buscar bandido: "+err.Error(), 500)
		}
		return
	}

	o.Links = generateLinks(o.ID)
	sendResponse(w, 200, true, o, "", nil)
}

// POST /v1/outlaws - Cria novo bandido
func createOutlaw(w http.ResponseWriter, r *http.Request) {
	var o Outlaw
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		sendError(w, "JSON inválido", 400)
		return
	}

	if o.Name == "" || o.Crime == "" || o.Reward == 0 {
		sendError(w, "Campos obrigatórios: name, reward, crime", 400)
		return
	}

	err := db.QueryRow(
		"INSERT INTO outlaws (name, reward, crime) VALUES ($1, $2, $3) RETURNING id, created_at",
		o.Name, o.Reward, o.Crime).Scan(&o.ID, &o.CreatedAt)

	if err != nil {
		sendError(w, "Erro ao criar bandido: "+err.Error(), 500)
		return
	}

	o.Links = generateLinks(o.ID)
	sendResponse(w, 201, true, o, "Bandido criado com sucesso", nil)
}

// PUT /v1/outlaws/{id} - Atualiza bandido
func updateOutlaw(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	var o Outlaw
	
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		sendError(w, "JSON inválido", 400)
		return
	}

	result, err := db.Exec(
		"UPDATE outlaws SET name=$1, reward=$2, crime=$3 WHERE id=$4",
		o.Name, o.Reward, o.Crime, id)

	if err != nil {
		sendError(w, "Erro ao atualizar: "+err.Error(), 500)
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		sendError(w, "Bandido não encontrado", 404)
		return
	}

	sendResponse(w, 200, true, nil, "Bandido atualizado com sucesso", generateLinks(id))
}

// DELETE /v1/outlaws/{id} - Remove bandido
func deleteOutlaw(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	result, err := db.Exec("DELETE FROM outlaws WHERE id = $1", id)

	if err != nil {
		sendError(w, "Erro ao deletar: "+err.Error(), 500)
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		sendError(w, "Bandido não encontrado", 404)
		return
	}

	links := map[string]string{
		"collection": "http://localhost:8080/v1/outlaws",
		"create":     "http://localhost:8080/v1/outlaws",
	}
	sendResponse(w, 200, true, nil, "Bandido deletado com sucesso", links)
}

// Gera links HATEOAS
func generateLinks(id int) map[string]string {
	baseURL := "http://localhost:8080/v1/outlaws"
	links := map[string]string{
		"self":       baseURL,
		"collection": baseURL,
	}

	if id > 0 {
		idStr := strconv.Itoa(id)
		links["self"] = baseURL + "/" + idStr
		links["update"] = baseURL + "/" + idStr
		links["delete"] = baseURL + "/" + idStr
	} else {
		links["create"] = baseURL
	}

	return links
}