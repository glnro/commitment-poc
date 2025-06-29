package main

import (
	"commitment-service/internal/utils"
	"commitment-service/pkg/service"
	"commitment-service/pkg/types"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"log"
	"net/http"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	config := &types.Config{
		L1RPC:       utils.GetEnv("L1_RPC", "http://localhost:8545"),
		L2RPC:       utils.GetEnv("L2_RPC", "http://localhost:9545"),
		L2OOAddress: utils.GetEnv("L2OO_ADDRESS", "0x0000000000000000000000000000000000000000"),
		Port:        utils.GetEnv("PORT", "8080"),
		DatabaseURL: utils.GetEnv("DATABASE_URL", "postgres://op-succinct@localhost:5432/op-succinct"),
	}

	service, err := service.NewService(config)
	if err != nil {
		log.Fatalf("Failed to create service: %v", err)
	}

	//TODO: Move to separate constructor

	// Setup router
	router := mux.NewRouter()

	// Apply CORS middleware
	router.Use(utils.CorsMiddleware)

	// Root endpoint
	router.HandleFunc("/", service.HandleRoot).Methods("GET")

	// Health check
	router.HandleFunc("/health", service.HandleHealth).Methods("GET")

	// API endpoints
	router.HandleFunc("/api/commitment/status", service.HandleCommitmentStatus).Methods("GET")
	router.HandleFunc("/api/transaction/{txHash}", service.HandleTransactionStatus).Methods("GET")

	// Metrics endpoint
	router.HandleFunc("/metrics", service.HandleMetrics).Methods("GET")

	// Start server
	log.Printf("Starting server on port %s", config.Port)
	log.Printf("API Documentation: http://localhost:%s/", config.Port)
	log.Fatal(http.ListenAndServe(":"+config.Port, router))
}
