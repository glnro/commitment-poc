package types

import (
	"time"
)

type CommitmentStatus struct {
	LatestBlockNumber   uint64    `json:"latestBlockNumber"`
	LatestOutputIndex   uint64    `json:"latestOutputIndex"`
	NextBlockNumber     uint64    `json:"nextBlockNumber"`
	LastProposalTime    time.Time `json:"lastProposalTime"`
	TotalCommitments    uint64    `json:"totalCommitments"`
	IsServiceHealthy    bool      `json:"isServiceHealthy"`
	LastCommitmentHash  string    `json:"lastCommitmentHash"`
	ProofGenerationTime string    `json:"proofGenerationTime"`
	Uptime              string    `json:"uptime"`
}

type TransactionStatus struct {
	TxHash            string    `json:"txHash"`
	BlockNumber       uint64    `json:"blockNumber"`
	Status            string    `json:"status"`
	Committed         bool      `json:"committed"`
	CommitmentAt      time.Time `json:"commitmentAt"`
	ProofHash         string    `json:"proofHash"`
	GasUsed           uint64    `json:"gasUsed"`
	EffectiveGasPrice string    `json:"effectiveGasPrice"`
}

type HealthStatus struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Version   string            `json:"version"`
	Services  map[string]string `json:"services"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}
