package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the application
type Config struct {
	L1RPC       string
	L2RPC       string
	L2OOAddress string
	Port        string
	DatabaseURL string
}

// Load loads configuration from environment variables
func Load(configFile string) *Config {
	// Load environment variables from file
	if err := godotenv.Load(configFile); err != nil {
		log.Printf("Warning: Could not load .env file: %v", err)
	}

	return &Config{
		L1RPC:       getEnv("L1_RPC_URL", "http://localhost:8545"),
		L2RPC:       getEnv("L2_RPC_URL", "http://localhost:9545"),
		L2OOAddress: getEnv("L2OO_ADDRESS", "0x5FbDB2315678afecb367f032d93F642f64180aa3"),
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://user:pass@localhost:5432/commitments"),
	}
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
