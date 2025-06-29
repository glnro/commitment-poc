## Commitment Contracts

![CI](https://github.com/glnro/commitment-poc/actions/workflows/contracts-test.yml/badge.svg)

This guide instructs on the deployment of the OP Succinct Commitment Storage contract using Docker and Anvil.

## Overview
The `CommitmentStorage` contract is the singular smart contract that:
- **Stores commitments** with ZK proofs on L1
- **Verifies proofs** before accepting commitments
- **Provides finality** guarantees for L2 transactions
- **Manages access** control for proposers

## Architecture Context

**This step deploys the L1 contract** that will receive commitments from the commitment service.

![architecture context](docs/arch_1.png)

## Prerequisites
- Go 1.23+
- Foundry
- Docker

## Quick Start

### 1. Deploy Contracts

These targets will:
- Start Anvil (local Ethereum instance)
- Deploy the CommitmentStorage contract
- Run tests to verify deployment

```bash
cd contracts

make setup-env      # One time setup

make anvil-start    # Start Anvil
make deploy-manual  # Deploy contract with forge
make test-deployed  # Test with forge
make anvil-stop     # Stop Anvil
```

### 2. Verify Deployment

After deployment, you should see the following output:
```
== Logs ==
  CommitmentStorage deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  Added deployer as proposer
  Deployment info saved to deployment.txt
  
##### anvil-hardhat
✅  [Success]Hash: 0x1b028f8b27a8cda3b08e3fa101be77565692eaf42868e2f15e0bcf05ea15e09d
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Block: 190

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
Transactions saved to: /user-path/commitment-poc/contracts/broadcast/Deploy.s.sol/31337/run-latest.json
```

Additionally run the tests against the deployment:
```bash
make test-deployed
```

### 3. Optional Debugging

The following targets can be used to debug the anvil deployment:

```bash
make anvil-log      # View anvil logs
make anvil-health   # Anvil healthcheck
make anvil-deug     # Run anvil debug check
```
