FROM golang:1.21-alpine

WORKDIR /app

COPY api-go.go .

RUN go mod init api-go
RUN go get github.com/gorilla/mux github.com/lib/pq
RUN go build -o /api-go api-go-new.go

EXPOSE 8080

CMD ["/api-go"]