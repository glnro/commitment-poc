# OP Succinct Commitment Storage Service

![CI](https://github.com/glnro/commitment-poc/actions/workflows/contracts-test.yml/badge.svg)

A commitment storage service that integrates with OP Stack and OP Succinct for zero-knowledge proof-based finality.

## Prerequisites

- Go 1.23+
- Foundry
- Docker

---

> [!warning]
> WIP

## Project Structure

```
commitment-poc/
├── commitment-service/                 # Commitment storage service
│   ├── cmd/                            # CLI and server applications
│   ├── pkg/                            # Service and handlers
│   ├── internal/                       # Config and utilities
│   ├── docker-compose.yml              # Service deployment
│   └── Makefile
├── contracts/                          # L1 Smart contracts for commitment storage
│   ├── src/                            # Contracts
│   ├── scripts/                         # Deployment scripts
│   ├── test/                           # Contract tests
│   ├── docker-compose.contracts.yml    # Anvil deployment
│   └── Makefile
└── README.md
```

## Key Components

### CommitmentStorage Contract
- **Location**: `contracts/src/CommitmentStorage.sol`
- **Purpose**: Stores commitments with ZK proofs on L1
- **Features**:
    - Submit commitments with proofs
    - Verify transaction inclusion
    - Access control for proposers

### Commitment Service
- **Location**: `commitment-service/`
- **Purpose**: HTTP API and CLI for commitment operations
- **Features**:
    - REST API for commitment queries
    - CLI for monitoring and interaction
    - Integration with OP Stack