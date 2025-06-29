package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/mux"

	"commitment-service/pkg/service"
)

// Handler handles HTTP requests
type Handler struct {
	service *service.Service
}

// NewHandler creates a new handler instance
func NewHandler(svc *service.Service) *Handler {
	return &Handler{
		service: svc,
	}
}

// HealthStatus represents the health check response
type HealthStatus struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Version   string            `json:"version"`
	Services  map[string]string `json:"services"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// HandleRoot handles the root endpoint
func (h *Handler) HandleRoot(w http.ResponseWriter, r *http.Request) {
	info := map[string]interface{}{
		"service": "OP Succinct Commitment Storage Service",
		"version": "1.0.0",
		"endpoints": map[string]string{
			"health":             "/health",
			"commitment_status":  "/status",
			"transaction_status": "/tx/{txHash}",
			"metrics":            "/metrics",
		},
		"uptime": h.service.GetUptime().String(),
	}

	sendJSONResponse(w, info, http.StatusOK)
}

// HandleHealth handles the health check endpoint
func (h *Handler) HandleHealth(w http.ResponseWriter, r *http.Request) {
	health := HealthStatus{
		Status:    "healthy",
		Timestamp: time.Now().Format(time.RFC3339),
		Version:   "1.0.0",
		Services: map[string]string{
			"l1_connection": "connected",
			"l2_connection": "connected",
			"database":      "connected",
		},
	}

	if !h.service.CheckServiceHealth() {
		health.Status = "unhealthy"
		health.Services["l1_connection"] = "disconnected"
		health.Services["l2_connection"] = "disconnected"
	}

	sendJSONResponse(w, health, http.StatusOK)
}

// HandleCommitmentStatus handles the commitment status endpoint
func (h *Handler) HandleCommitmentStatus(w http.ResponseWriter, r *http.Request) {
	status, err := h.service.GetCommitmentStatus()
	if err != nil {
		sendErrorResponse(w, "Failed to get commitment status", err.Error(), http.StatusInternalServerError)
		return
	}

	sendJSONResponse(w, status, http.StatusOK)
}

// HandleTransactionStatus handles the transaction status endpoint
func (h *Handler) HandleTransactionStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	txHash := vars["txHash"]

	if txHash == "" {
		sendErrorResponse(w, "Missing transaction hash", "Transaction hash is required", http.StatusBadRequest)
		return
	}

	status, err := h.service.GetTransactionStatus(txHash)
	if err != nil {
		sendErrorResponse(w, "Failed to get transaction status", err.Error(), http.StatusInternalServerError)
		return
	}

	sendJSONResponse(w, status, http.StatusOK)
}

// HandleMetrics handles the metrics endpoint
func (h *Handler) HandleMetrics(w http.ResponseWriter, r *http.Request) {
	// Prometheus metrics endpoint
	metrics := fmt.Sprintf(`# HELP commitment_service_uptime_seconds Total uptime in seconds
# TYPE commitment_service_uptime_seconds counter
commitment_service_uptime_seconds %f

# HELP commitment_service_health_status Service health status (1=healthy, 0=unhealthy)
# TYPE commitment_service_health_status gauge
commitment_service_health_status %d

# HELP commitment_service_total_commitments Total number of commitments
# TYPE commitment_service_total_commitments counter
commitment_service_total_commitments %d
`,
		h.service.GetUptime().Seconds(),
		boolToInt(h.service.CheckServiceHealth()),
		uint64(h.service.GetUptime().Hours()), // Mock data
	)

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(metrics))
}

// Utility functions
func sendJSONResponse(w http.ResponseWriter, data interface{}, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func sendErrorResponse(w http.ResponseWriter, title, message string, statusCode int) {
	errorResp := ErrorResponse{
		Error:   title,
		Code:    statusCode,
		Message: message,
	}
	sendJSONResponse(w, errorResp, statusCode)
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
