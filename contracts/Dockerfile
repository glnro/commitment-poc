FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /app

# Copy contract files
COPY contracts/ .

# Install dependencies
RUN forge install OpenZeppelin/openzeppelin-contracts@v4.9.5 --no-commit

RUN forge install foundry-rs/forge-std --no-commit

# Build contracts
RUN forge build

# Create deployment script
COPY contracts/script/deploy-contracts.sh /app/deploy-contracts.sh
RUN chmod +x /app/deploy.sh

# Default command
CMD ["/app/deploy-contracts.sh"]