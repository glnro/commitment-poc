# Contracts Makefile
.PHONY: help build test deploy clean anvil-start anvil-stop anvil-logs deploy-manual test-deployed

# VARS
DOCKER_COMPOSE = docker-compose -f docker-compose.contracts.yml
ANVIL_URL = http://localhost:8545

# Default target
help:
	@echo "Eth Contracts"
	@echo ""
	@echo "Available commands:"
	@echo "  setup-env     - Bootstrap test .env"
	@echo "  build         - Build contracts with Foundry"
	@echo "  test          - Run contract tests"
	@echo "  deploy        - Deploy contracts (requires PRIVATE_KEY)"
	@echo "  clean         - Clean build artifacts"
	@echo ""
	@echo "Manual deployment commands:"
	@echo "  anvil-start   - Start Anvil blockchain"
	@echo "  anvil-stop    - Stop Anvil blockchain"
	@echo "  anvil-logs    - View Anvil logs"
	@echo "  deploy-manual - Deploy contracts to Anvil"
	@echo "  test-deployed - Test deployed contracts"
	@echo "  deploy-full   - Complete manual deployment (start + deploy + test)"

# Install dependencies
.PHONY: install-deps
install-deps:
	forge install OpenZeppelin/openzeppelin-contracts@v4.9.5 --no-commit
	forge install foundry-rs/forge-std --no-commit

# Build
.PHONY: build
build: install-deps
	forge build

# Test
.PHONY: test
test: install-deps
	forge test -vv

# Reset dependencies
.PHONY: reset
reset:
	@echo "Cleaning build artifacts..."
	rm -rf out/ cache/ lib/
	forge clean
	@echo "Reinstalling dependencies..."
	forge install OpenZeppelin/openzeppelin-contracts@v4.9.5 --no-commit
	forge install foundry-rs/forge-std --no-commit --no-git
	forge build
	forge test -vv

# Setup environment file
setup-env:
	@if [ ! -f ".env" ]; then \
		cp ./test/env.test .env; \
		echo "Created .env file from env.example"; \
		echo "Edit .env file to use a different private key"; \
	else \
		echo " .env file already exists"; \
	fi


# Manual Deployment

# Start Anvil
anvil-start:
	@echo "Starting Anvil blockchain..."
	docker-compose -f docker-compose.contracts.yml up -d anvil
	@echo "Waiting for Anvil to be ready..."
	@sleep 10
	@echo "Testing Anvil connection..."
	@for i in 1 2 3 4 5; do \
		if curl -s -X POST -H "Content-Type: application/json" \
			--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
			http://localhost:8545 > /dev/null 2>&1; then \
			echo "Anvil is running and responding"; \
			break; \
		else \
			echo "Waiting for Anvil... (attempt $$i/5)"; \
			sleep 5; \
		fi; \
	done

# Debug Anvil connectivity
anvil-debug:
	@echo "Debugging Anvil connectivity..."
	@echo ""
	@echo "1. Checking container status:"
	@docker-compose -f docker-compose.contracts.yml ps anvil
	@echo ""
	@echo "2. Checking container logs:"
	@docker-compose -f docker-compose.contracts.yml logs --tail=5 anvil
	@echo ""
	@echo "3. Checking if port 8545 is listening:"
	@netstat -an | grep 8545 || echo "Port 8545 not found in netstat"
	@echo ""
	@echo "4. Testing direct connection:"
	@curl -v http://localhost:8545 2>&1 | head -10 || echo "Direct connection failed"
	@echo ""
	@echo "5. Testing RPC call:"
	@curl -s -X POST -H "Content-Type: application/json" \
		--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
		http://localhost:8545 || echo "RPC call failed"

# Check Anvil health and block production
anvil-health:
	@echo "Checking Anvil health..."
	@if ! curl -s http://localhost:8545 > /dev/null 2>&1; then \
		echo "Anvil not running"; \
		exit 1; \
	fi
	@echo "Anvil is responding"
	@echo "Checking block production..."
	@BLOCK1=$$(curl -s -X POST -H "Content-Type: application/json" \
		--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
		http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "0"); \
	sleep 3; \
	BLOCK2=$$(curl -s -X POST -H "Content-Type: application/json" \
		--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
		http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "0"); \
	BLOCK1_DEC=$$(printf "%d" $$BLOCK1 2>/dev/null || echo 0); \
	BLOCK2_DEC=$$(printf "%d" $$BLOCK2 2>/dev/null || echo 0); \
	if [ $$BLOCK2_DEC -gt $$BLOCK1_DEC ]; then \
		echo "Anvil producing blocks ($$BLOCK1_DEC → $$BLOCK2_DEC)"; \
	else \
		echo "Anvil is running but not producing blocks ($$BLOCK1_DEC = $$BLOCK2_DEC)"; \
		echo "   This might be normal if --no-mining is set"; \
	fi

# Stop Anvil
anvil-stop:
	@echo "Stopping Anvil blockchain..."
	docker-compose -f docker-compose.contracts.yml down
	@echo "Anvil stopped"

# View Anvil logs
anvil-logs:
	@echo "Viewing Anvil logs..."
	docker-compose -f docker-compose.contracts.yml logs -f anvil


# Deploy contracts to Anvil
deploy-manual:
	@echo "Deploying contracts to Anvil..."
	@if ! curl -s http://localhost:8545 > /dev/null 2>&1; then \
		echo "Anvil is not running. Run 'make anvil-start' first"; \
		exit 1; \
	fi
	@if [ ! -f ".env" ]; then \
		echo ".env file not found. Run 'make setup-env' first"; \
		exit 1; \
	fi
	@echo "Deploying with forge..."
	@source .env && forge script scripts/Deploy.s.sol:DeployCommitmentStorage --rpc-url $$L1_RPC_URL --broadcast
	@if [ -f "broadcast/Deploy.s.sol/31337/run-latest.json" ]; then \
		echo "Contract deployed successfully!"; \
		echo ""; \
		echo "Deployment Information:"; \
		echo "=========================="; \
		CONTRACT_ADDRESS=$$(jq -r '.transactions[] | select(.contractName=="CommitmentStorage") | .contractAddress' broadcast/Deploy.s.sol/31337/run-latest.json); \
		if [ ! -z "$$CONTRACT_ADDRESS" ] && [ "$$CONTRACT_ADDRESS" != "null" ]; then \
			echo "Contract Address: $$CONTRACT_ADDRESS"; \
			mkdir -p deployment; \
			echo "CONTRACT_ADDRESS=$$CONTRACT_ADDRESS" > deployment/contract.env; \
			echo "CommitmentStorage deployed at: $$CONTRACT_ADDRESS" > deployment/deployment.txt; \
			echo "Deployer: $$(jq -r '.transactions[] | select(.contractName=="CommitmentStorage") | .from' broadcast/Deploy.s.sol/31337/run-latest.json)" >> deployment/deployment.txt; \
			echo "Network: 31337" >> deployment/deployment.txt; \
			cat deployment/deployment.txt; \
		else \
			echo "Could not extract contract address from deployment"; \
		fi; \
	else \
		echo "Deployment failed. Check the logs above"; \
		exit 1; \
	fi


# Test deployed contracts
test-deployed:
	@echo "Testing deployed contracts..."
	forge test --rpc-url http://localhost:8545


# Clean up everything
clean-all: anvil-stop
	@echo "Cleaning up deployment..."
	rm -rf deployment/ broadcast/
	@echo "Cleanup complete"