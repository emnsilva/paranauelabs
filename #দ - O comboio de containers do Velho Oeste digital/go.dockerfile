FROM golang:1.21-alpine

WORKDIR /app

COPY api-go.go .

RUN go mod init api-go && \
    go get github.com/gorilla/mux github.com/lib/pq && \
    go build -o /api-go api-go.go

EXPOSE 8080

CMD ["/api-go"]