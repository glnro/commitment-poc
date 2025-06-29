package server

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"commitment-service/pkg/handlers"
	"commitment-service/pkg/service"
)

// Server represents the HTTP server
type Server struct {
	router  *mux.Router
	handler *handlers.Handler
	port    string
}

// NewServer creates a new server instance
func NewServer(svc *service.Service, port string) *Server {
	handler := handlers.NewHandler(svc)
	router := mux.NewRouter()

	// Apply middleware
	router.Use(corsMiddleware)

	// Setup routes
	setupRoutes(router, handler)

	return &Server{
		router:  router,
		handler: handler,
		port:    port,
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	log.Printf("Starting commitment storage service on port %s", s.port)
	return http.ListenAndServe(":"+s.port, s.router)
}

// setupRoutes configures all the routes
func setupRoutes(router *mux.Router, handler *handlers.Handler) {
	// API routes
	router.HandleFunc("/", handler.HandleRoot).Methods("GET")
	router.HandleFunc("/health", handler.HandleHealth).Methods("GET")
	router.HandleFunc("/status", handler.HandleCommitmentStatus).Methods("GET")
	router.HandleFunc("/tx/{txHash}", handler.HandleTransactionStatus).Methods("GET")
	router.HandleFunc("/metrics", handler.HandleMetrics).Methods("GET")
}

// corsMiddleware handles CORS headers
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
