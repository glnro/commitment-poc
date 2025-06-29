package service

import (
	"context"
	"fmt"
	"time"

	eth "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	"commitment-service/internal/config"
)

// Service handles the core business logic for commitment tracking
type Service struct {
	config    *config.Config
	l1Client  *ethclient.Client
	l2Client  *ethclient.Client
	l2ooAddr  common.Address
	startTime time.Time
}

// CommitmentStatus represents the current status of commitments
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

// TransactionStatus represents the status of a transaction
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

// NewService creates a new service instance
func NewService(cfg *config.Config) (*Service, error) {
	l1Client, err := ethclient.Dial(cfg.L1RPC)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	l2Client, err := ethclient.Dial(cfg.L2RPC)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L2: %w", err)
	}

	l2ooAddr := common.HexToAddress(cfg.L2OOAddress)

	return &Service{
		config:    cfg,
		l1Client:  l1Client,
		l2Client:  l2Client,
		l2ooAddr:  l2ooAddr,
		startTime: time.Now(),
	}, nil
}

// GetCommitmentStatus returns the current commitment status
func (s *Service) GetCommitmentStatus() (*CommitmentStatus, error) {
	// Get latest block number from L2OutputOracle contract
	latestBlockNumber, err := s.getLatestBlockNumber()
	if err != nil {
		return nil, err
	}

	// Get latest output index
	latestOutputIndex, err := s.getLatestOutputIndex()
	if err != nil {
		return nil, err
	}

	// Calculate next block number
	nextBlockNumber := latestBlockNumber + 1800 // Default submission interval

	// Get last proposal time (simplified - in real implementation, you'd query the contract)
	lastProposalTime := time.Now().Add(-10 * time.Minute) // Mock data

	// Get total commitments (simplified)
	totalCommitments := latestOutputIndex + 1

	// Check service health
	isServiceHealthy := s.checkServiceHealth()

	// Calculate uptime
	uptime := time.Since(s.startTime).String()

	return &CommitmentStatus{
		LatestBlockNumber:   latestBlockNumber,
		LatestOutputIndex:   latestOutputIndex,
		NextBlockNumber:     nextBlockNumber,
		LastProposalTime:    lastProposalTime,
		TotalCommitments:    totalCommitments,
		IsServiceHealthy:    isServiceHealthy,
		LastCommitmentHash:  "0xabc123...", // Mock data
		ProofGenerationTime: "5 minutes",   // Mock data
		Uptime:              uptime,
	}, nil
}

// GetTransactionStatus returns the status of a specific transaction
func (s *Service) GetTransactionStatus(txHash string) (*TransactionStatus, error) {
	// Get transaction receipt from L2
	hash := common.HexToHash(txHash)
	receipt, err := s.l2Client.TransactionReceipt(context.Background(), hash)
	if err != nil {
		return nil, err
	}

	// Get transaction details
	tx, _, err := s.l2Client.TransactionByHash(context.Background(), hash)
	if err != nil {
		return nil, err
	}

	// Check if transaction is committed (simplified logic)
	latestCommittedBlock := s.getLatestCommittedBlock()
	committed := receipt.BlockNumber.Uint64() <= latestCommittedBlock

	// Determine status
	status := "pending"
	if receipt.Status == 1 {
		status = "confirmed"
		if committed {
			status = "committed"
		}
	} else {
		status = "failed"
	}

	return &TransactionStatus{
		TxHash:            txHash,
		BlockNumber:       receipt.BlockNumber.Uint64(),
		Status:            status,
		Committed:         committed,
		CommitmentAt:      time.Now().Add(-5 * time.Minute), // Mock data
		ProofHash:         "0xdef456...",                    // Mock data
		GasUsed:           receipt.GasUsed,
		EffectiveGasPrice: tx.GasPrice().String(),
	}, nil
}

// CheckServiceHealth checks if the service is healthy
func (s *Service) CheckServiceHealth() bool {
	return s.checkServiceHealth()
}

// GetUptime returns the service uptime
func (s *Service) GetUptime() time.Duration {
	return time.Since(s.startTime)
}

// Private methods
func (s *Service) getLatestBlockNumber() (uint64, error) {
	// Call the latestBlockNumber() function on L2OutputOracle contract
	// This is a simplified version - in real implementation, you'd use contract ABI
	data := []byte("0x2e17de78") // Function selector for latestBlockNumber()

	msg := eth.CallMsg{
		To:   &s.l2ooAddr,
		Data: data,
	}

	result, err := s.l1Client.CallContract(context.Background(), msg, nil)
	if err != nil {
		return 0, err
	}

	// Parse the result (simplified)
	if len(result) >= 32 {
		return uint64(result[31]), nil
	}

	return 0, fmt.Errorf("invalid result length")
}

func (s *Service) getLatestOutputIndex() (uint64, error) {
	// Call the latestOutputIndex() function on L2OutputOracle contract
	data := []byte("0x2e17de78") // Function selector for latestOutputIndex()

	msg := eth.CallMsg{
		To:   &s.l2ooAddr,
		Data: data,
	}

	result, err := s.l1Client.CallContract(context.Background(), msg, nil)
	if err != nil {
		return 0, err
	}

	if len(result) >= 32 {
		return uint64(result[31]), nil
	}

	return 0, fmt.Errorf("invalid result length")
}

func (s *Service) checkServiceHealth() bool {
	// Check if the service is healthy by verifying connections
	_, err := s.l1Client.BlockNumber(context.Background())
	if err != nil {
		return false
	}

	_, err = s.l2Client.BlockNumber(context.Background())
	if err != nil {
		return false
	}

	return true
}

func (s *Service) getLatestCommittedBlock() uint64 {
	// Get the latest block number that has been committed to L1
	// This is a simplified version - in real implementation, you'd query the contract
	latestBlock, err := s.l2Client.BlockNumber(context.Background())
	if err != nil {
		return 0
	}

	// Assume blocks older than 10 blocks are committed
	if latestBlock > 10 {
		return latestBlock - 10
	}
	return 0
}
