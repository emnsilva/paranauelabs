FROM golang:1.21-alpine

WORKDIR /app

# Copia o código e os arquivos Swagger
COPY APIs/api-go.go .
COPY swagger/ ./swagger/

# Inicializa e baixa dependências
RUN go mod init api-go
RUN go get github.com/gorilla/mux
RUN go get github.com/lib/pq

# Compila a aplicação
RUN go build -o main .

EXPOSE 8080

CMD ["./main"]