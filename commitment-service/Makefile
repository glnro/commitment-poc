# OP Succinct Commitment Storage Service Makefile

.PHONY: help build build-server build-cli clean test docker-build docker-run docker-stop install-deps

# Default target
help:
	@echo "OP Succinct Commitment Storage Service"
	@echo ""
	@echo "Available commands:"
	@echo "  build         - Build both server and CLI binaries"
	@echo "  build-server  - Build only the server binary"
	@echo "  build-cli     - Build only the CLI binary"
	@echo "  clean         - Clean build artifacts"
	@echo "  test          - Run tests"
	@echo "  docker-build  - Build Docker images"
	@echo "  docker-run    - Start all services with Docker"
	@echo "  docker-stop   - Stop all Docker services"
	@echo "  install-deps  - Install Go dependencies"
	@echo "  server        - Run the server locally"
	@echo "  status        - Check commitment status"
	@echo "  tx-status     - Check transaction status (usage: make tx-status TXHASH=0x...)"
	@echo "  create-tx     - Create a transaction (usage: make create-tx TO=0x... VALUE=0.1)"
	@echo ""
	@echo "Contract commands:"
	@echo "  contract-build    - Build the smart contract"
	@echo "  contract-test     - Run contract tests"
	@echo "  contract-deploy   - Deploy the contract (requires PRIVATE_KEY env var)"
	@echo "  contract-verify   - Verify the contract on Etherscan"

# Build both binaries
build: build-server build-cli

# Build server binary
build-server:
	@echo "Building server binary..."
	go build -o bin/commitment-server ./cmd/server

# Build CLI binary
build-cli:
	@echo "Building CLI binary..."
	go build -o bin/commitment-cli ./cmd/cli

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	rm -rf contracts/out/

# Run tests
test:
	@echo "Running tests..."
	go test ./...

# Install Go dependencies
install-deps:
	@echo "Installing Go dependencies..."
	go mod download
	go mod tidy

# Docker commands
docker-build:
	@echo "Building Docker images..."
	docker-compose build

docker-run:
	@echo "Starting services with Docker..."
	docker-compose up -d

docker-stop:
	@echo "Stopping Docker services..."
	docker-compose down

# Local development commands
server:
	@echo "Starting server locally..."
	go run ./cmd/server

status:
	@echo "Checking commitment status..."
	go run ./cmd/cli status

tx-status:
	@if [ -z "$(TXHASH)" ]; then \
		echo "Error: TXHASH parameter is required"; \
		echo "Usage: make tx-status TXHASH=0x..."; \
		exit 1; \
	fi
	@echo "Checking transaction status for $(TXHASH)..."
	go run ./cmd/cli tx-status $(TXHASH)

create-tx:
	@if [ -z "$(TO)" ]; then \
		echo "Error: TO parameter is required"; \
		echo "Usage: make create-tx TO=0x... VALUE=0.1"; \
		exit 1; \
	fi
	@echo "Creating transaction to $(TO)..."
	go run ./cmd/cli create-tx --to $(TO) --value $(VALUE)

# Contract commands
contract-build:
	@echo "Building smart contract..."
	cd contracts && forge build

contract-test:
	@echo "Running contract tests..."
	cd contracts && forge test -vv

contract-deploy:
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "Error: PRIVATE_KEY environment variable is required"; \
		echo "Usage: PRIVATE_KEY=0x... make contract-deploy"; \
		exit 1; \
	fi
	@echo "Deploying contract..."
	cd contracts && forge script script/Deploy.s.sol:DeployCommitmentStorage --rpc-url $(L1_RPC_URL) --broadcast --verify

contract-verify:
	@if [ -z "$(CONTRACT_ADDRESS)" ]; then \
		echo "Error: CONTRACT_ADDRESS environment variable is required"; \
		echo "Usage: CONTRACT_ADDRESS=0x... make contract-verify"; \
		exit 1; \
	fi
	@echo "Verifying contract..."
	cd contracts && forge verify-contract $(CONTRACT_ADDRESS) src/CommitmentStorage.sol:CommitmentStorage --chain-id $(CHAIN_ID) --etherscan-api-key $(ETHERSCAN_API_KEY)

# Create bin directory if it doesn't exist
bin:
	mkdir -p bin

# Development setup
dev-setup: install-deps bin build contract-build
	@echo "Development environment setup complete!"
	@echo ""
	@echo "Available commands:"
	@echo "  make server     - Start the HTTP server"
	@echo "  make status     - Check commitment status"
	@echo "  make tx-status TXHASH=0x... - Check transaction status"
	@echo "  make create-tx TO=0x... VALUE=0.1 - Create transaction"
	@echo "  make contract-test - Run contract tests"
	@echo "  make contract-deploy - Deploy contract (requires PRIVATE_KEY)"

# Variables
DOCKER_COMPOSE = docker compose
GO = go
NODE = node
NPM = npm

# Docker services
.PHONY: build
build:
	$(DOCKER_COMPOSE) build

.PHONY: up
up:
	$(DOCKER_COMPOSE) up -d

.PHONY: up-logs
up-logs:
	$(DOCKER_COMPOSE) up

.PHONY: down
down:
	$(DOCKER_COMPOSE) down

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) logs -f

.PHONY: logs-service
logs-service:
	$(DOCKER_COMPOSE) logs -f $(SERVICE)

.PHONY: restart
restart:
	$(DOCKER_COMPOSE) restart

.PHONY: status
status:
	$(DOCKER_COMPOSE) ps

# Backend (Go)
.PHONY: backend-build
backend-build:
	cd backend && $(GO) build -o commitment-service main.go

.PHONY: backend-run
backend-run:
	cd backend && $(GO) run main.go

.PHONY: backend-test
backend-test:
	cd backend && $(GO) test ./...

.PHONY: backend-deps
backend-deps:
	cd backend && $(GO) mod tidy

# Frontend (Node.js)
.PHONY: frontend-install
frontend-install:
	cd frontend && $(NPM) install

.PHONY: frontend-run
frontend-run:
	cd frontend && $(NPM) start

.PHONY: frontend-dev
frontend-dev:
	cd frontend && $(NPM) run dev

# Transaction scripts
.PHONY: create-tx
create-tx:
	cd frontend && $(NODE) scripts/create-transaction.js $(ARGS)

.PHONY: check-status
check-status:
	cd frontend && $(NODE) scripts/check-status.js $(ARGS)

.PHONY: health
health:
	curl -f http://localhost:8080/health

.PHONY: metrics
metrics:
	curl http://localhost:8080/metrics

# Contract deployment
.PHONY: deploy-mock-verifier
deploy-mock-verifier:
	cd contracts && forge script script/validity/DeployMockVerifier.s.sol --rpc-url $(L1_RPC) --broadcast --verify

.PHONY: deploy-oracle
deploy-oracle:
	cd contracts && forge script script/validity/OPSuccinctDeployer.s.sol --rpc-url $(L1_RPC) --broadcast --verify

.PHONY: deploy-fdg-contracts
deploy-fdg-contracts:
	cd contracts && forge script script/fp/DeployOPSuccinctFDG.s.sol --rpc-url $(L1_RPC) --broadcast --verify

# Database
.PHONY: db
db:
	$(DOCKER_COMPOSE) exec postgres psql -U op-succinct -d op-succinct

.PHONY: migrate
migrate:
	$(DOCKER_COMPOSE) exec postgres psql -U op-succinct -d op-succinct -f /docker-entrypoint-initdb.d/01_init.sql

# Contract interaction
.PHONY: contract-state
contract-state:
	cast call $(ADDRESS) "latestBlockNumber()" --rpc-url $(L1_RPC)

.PHONY: latest-output
latest-output:
	cast call $(ADDRESS) "latestOutputIndex()" --rpc-url $(L1_RPC)

.PHONY: check-proposer
check-proposer:
	cast call $(CONTRACT) "approvedProposers(address)" $(ADDRESS) --rpc-url $(L1_RPC)

.PHONY: add-proposer
add-proposer:
	cast send $(CONTRACT) "addProposer(address)" $(ADDRESS) --rpc-url $(L1_RPC) --private-key $(PRIVATE_KEY)

.PHONY: update-interval
update-interval:
	cast send $(CONTRACT) "updateSubmissionInterval(uint256)" $(INTERVAL) --rpc-url $(L1_RPC) --private-key $(PRIVATE_KEY)

# Development
.PHONY: dev-setup
dev-setup:
	$(MAKE) backend-deps
	$(MAKE) frontend-install
	$(MAKE) build

.PHONY: dev-run
dev-run:
	$(MAKE) up
	$(MAKE) backend-run &
	$(MAKE) frontend-dev

# Monitoring
.PHONY: grafana
grafana:
	@echo "Grafana available at: http://localhost:3000"
	@echo "Username: admin"
	@echo "Password: admin"

.PHONY: prometheus
prometheus:
	@echo "Prometheus available at: http://localhost:9090"

# Cleanup
.PHONY: clean
clean:
	$(DOCKER_COMPOSE) down -v
	docker system prune -f

.PHONY: clean-all
clean-all:
	$(DOCKER_COMPOSE) down -v --rmi all
	docker system prune -af

# Examples
.PHONY: example-transfer
example-transfer:
	$(MAKE) create-tx ARGS="transfer -t 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6 -a 0.1"

.PHONY: example-status
example-status:
	$(MAKE) check-status ARGS="commitment"

.PHONY: example-watch
example-watch:
	$(MAKE) check-status ARGS="watch -i 10"

# Helpers
.PHONY: setup-env
setup-env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from template..."; \
		cp env.example .env; \
		echo "Please edit .env with your configuration"; \
	else \
		echo ".env file already exists"; \
	fi

.PHONY: validate-env
validate-env:
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Run 'make setup-env' first"; \
		exit 1; \
	fi
	@echo "Environment file validated"

# Quick start
.PHONY: quick-start
quick-start: setup-env validate-env
	@echo "Starting commitment storage service..."
	$(MAKE) build
	$(MAKE) up
	@echo "Service started! Check status with: make check-status ARGS=health"

# Show this help
.PHONY: show-help
show-help: help