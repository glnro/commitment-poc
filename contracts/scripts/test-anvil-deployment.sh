#!/bin/bash

echo "🧪 Testing Anvil Connection"
echo "==========================="

# Test if Anvil is running
echo "1. Checking if Anvil container is running..."
if docker-compose -f docker-compose.contracts.yml ps anvil | grep -q "Up"; then
    echo "✅ Anvil container is running"
else
    echo "❌ Anvil container is not running"
    echo "Starting Anvil..."
    docker-compose -f docker-compose.contracts.yml up -d anvil
    sleep 10
fi

# Test RPC connection
echo ""
echo "2. Testing RPC connection..."
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545)

if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
    echo "✅ RPC connection successful"
    echo "Response: $RESPONSE"
else
    echo "❌ RPC connection failed"
    echo "Response: $RESPONSE"
fi

# Test account balance
echo ""
echo "3. Testing account balance..."
ACCOUNT="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
BALANCE_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ACCOUNT\",\"latest\"],\"id\":1}" \
  http://localhost:8545)

if [ $? -eq 0 ] && [ ! -z "$BALANCE_RESPONSE" ]; then
    echo "✅ Balance check successful"
    echo "Response: $BALANCE_RESPONSE"
else
    echo "❌ Balance check failed"
    echo "Response: $BALANCE_RESPONSE"
fi

# Show container logs if there are issues
echo ""
echo "4. Container status:"
docker-compose -f docker-compose.contracts.yml ps

echo ""
echo "5. Recent logs:"
docker-compose -f docker-compose.contracts.yml logs --tail=10 anvil