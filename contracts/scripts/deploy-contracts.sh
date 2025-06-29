#!/bin/bash

set -e

echo "Deploying Commitment Storage Contracts"
echo "====================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Create deployment directory
mkdir -p deployment

# Step 1: Start Anvil
print_info "Starting Anvil local blockchain..."
docker-compose -f docker-compose.contracts.yml up -d anvil

# Wait for Anvil to be ready
print_info "Waiting for Anvil to be ready..."
sleep 5

# Test Anvil connection
if curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 > /dev/null; then
    print_status "Anvil is running and responding"
else
    echo "❌ Anvil is not responding. Please check the logs:"
    docker-compose -f docker-compose.contracts.yml logs anvil
    exit 1
fi

# Step 2: Deploy contracts
print_info "Deploying CommitmentStorage contract..."
docker-compose -f docker-compose.contracts.yml up contract-deployer

# Step 3: Get deployment info
if [ -f "deployment/deployment.txt" ]; then
    print_status "Contract deployed successfully!"
    echo ""
    echo "Deployment Information:"
    echo "=========================="
    cat deployment/deployment.txt
    echo ""

    # Extract contract address
    CONTRACT_ADDRESS=$(grep "CommitmentStorage deployed at:" deployment/deployment.txt | cut -d' ' -f4)
    if [ ! -z "$CONTRACT_ADDRESS" ]; then
        echo "🔗 Contract Address: $CONTRACT_ADDRESS"
        echo "CONTRACT_ADDRESS=$CONTRACT_ADDRESS" > deployment/contract.env
    fi
else
    echo "❌ Deployment failed. Check the logs:"
    docker-compose -f docker-compose.contracts.yml logs contract-deployer
    exit 1
fi

# Step 4: Test the contract
print_info "Testing deployed contract..."
docker-compose -f docker-compose.contracts.yml exec contract-deployer forge test --rpc-url http://anvil:8545

print_status "Contract deployment and testing complete!"
echo ""
echo "🎉 Next Steps:"
echo "=============="
echo "1. The contract is deployed and ready for use"
echo "2. You can interact with it using the address above"
echo "3. The commitment service can now use this contract"
echo ""
echo "To stop the test environment:"
echo "  docker-compose -f docker-compose.contracts.yml down"
echo ""
echo "To view logs:"
echo "  docker-compose -f docker-compose.contracts.yml logs -f"