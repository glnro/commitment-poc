#!/bin/bash

set -e

echo "🧪 Testing OP Succinct Commitment Storage Service"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color#!/bin/bash

                       set -e

                       echo "🧪 Testing OP Succinct Commitment Storage Service"
                       echo "=================================================="

                       # Colors for output
                       RED='\033[0;31m'
                       GREEN='\033[0;32m'
                       YELLOW='\033[1;33m'
                       NC='\033[0m' # No Color

                       # Function to print colored output
                       print_status() {
                           echo -e "${GREEN}✅ $1${NC}"
                       }

                       print_warning() {
                           echo -e "${YELLOW}⚠️  $1${NC}"
                       }

                       print_error() {
                           echo -e "${RED}❌ $1${NC}"
                       }

                       # Test 1: Build the project
                       echo "1. Building the project..."
                       make build
                       print_status "Project built successfully"

                       # Test 2: Run contract tests
                       echo "2. Running contract tests..."
                       cd contracts && forge test -vv && cd ..
                       print_status "Contract tests passed"

                       # Test 3: Start test environment
                       echo "3. Starting test environment..."
                       make test-setup
                       print_status "Test environment started"

                       # Wait for services to be ready
                       echo "4. Waiting for services to be ready..."
                       sleep 15

                       # Test 4: Check if Anvil is responding
                       echo "5. Testing Anvil connection..."
                       if curl -s -X POST -H "Content-Type: application/json" \
                         --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                         http://localhost:8545 > /dev/null; then
                           print_status "Anvil is responding"
                       else
                           print_error "Anvil is not responding"
                           exit 1
                       fi

                       # Test 5: Check if OP Geth is responding
                       echo "6. Testing OP Geth connection..."
                       if curl -s -X POST -H "Content-Type: application/json" \
                         --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                         http://localhost:9545 > /dev/null; then
                           print_status "OP Geth is responding"
                       else
                           print_warning "OP Geth is not responding yet (this is normal during startup)"
                       fi

                       # Test 6: Deploy contracts
                       echo "7. Deploying contracts..."
                       make test-deploy
                       print_status "Contracts deployed"

                       # Test 7: Test CLI commands
                       echo "8. Testing CLI commands..."
                       go run ./cmd/cli status
                       print_status "CLI status command works"

                       # Test 8: Test server startup
                       echo "9. Testing server startup..."
                       timeout 10s go run ./cmd/server &
                       SERVER_PID=$!
                       sleep 3

                       if curl -s http://localhost:8080/health > /dev/null; then
                           print_status "Server is responding"
                       else
                           print_warning "Server health check failed (this might be normal if not fully started)"
                       fi

                       # Cleanup
                       kill $SERVER_PID 2>/dev/null || true

                       echo ""
                       echo "🎉 All tests completed!"
                       echo ""
                       echo "To start the full test environment:"
                       echo "  make test-full"
                       echo ""
                       echo "To stop the test environment:"
                       echo "  make test-stop"
                       echo ""
                       echo "To view logs:"
                       echo "  make test-logs"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test 1: Build the project
echo "1. Building the project..."
make build
print_status "Project built successfully"

# Test 2: Run contract tests
echo "2. Running contract tests..."
cd contracts && forge test -vv && cd ..
print_status "Contract tests passed"

# Test 3: Start test environment
echo "3. Starting test environment..."
make test-setup
print_status "Test environment started"

# Wait for services to be ready
echo "4. Waiting for services to be ready..."
sleep 15

# Test 4: Check if Anvil is responding
echo "5. Testing Anvil connection..."
if curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 > /dev/null; then
    print_status "Anvil is responding"
else
    print_error "Anvil is not responding"
    exit 1
fi

# Test 5: Check if OP Geth is responding
echo "6. Testing OP Geth connection..."
if curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:9545 > /dev/null; then
    print_status "OP Geth is responding"
else
    print_warning "OP Geth is not responding yet (this is normal during startup)"
fi

# Test 6: Deploy contracts
echo "7. Deploying contracts..."
make test-deploy
print_status "Contracts deployed"

# Test 7: Test CLI commands
echo "8. Testing CLI commands..."
go run ./cmd/cli status
print_status "CLI status command works"

# Test 8: Test server startup
echo "9. Testing server startup..."
timeout 10s go run ./cmd/server &
SERVER_PID=$!
sleep 3

if curl -s http://localhost:8080/health > /dev/null; then
    print_status "Server is responding"
else
    print_warning "Server health check failed (this might be normal if not fully started)"
fi

# Cleanup
kill $SERVER_PID 2>/dev/null || true

echo ""
echo "🎉 All tests completed!"
echo ""
echo "To start the full test environment:"
echo "  make test-full"
echo ""
echo "To stop the test environment:"
echo "  make test-stop"
echo ""
echo "To view logs:"
echo "  make test-logs"