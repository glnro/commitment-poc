// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title CommitmentStorage
 * @dev Stores and verifies OP Succinct commitments with ZK proofs
 *
 * This contract is responsible for:
 * 1. Receiving commitments from authorized proposers
 * 2. Verifying ZK proofs before accepting commitments
 * 3. Storing commitment data for public verification
 * 4. Providing finality guarantees for L2 transactions
 */
contract CommitmentStorage is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Events
    event CommitmentSubmitted(
        uint256 indexed commitmentId,
        bytes32 indexed stateRoot,
        uint256 blockNumber,
        bytes32 proofHash,
        address indexed proposer,
        uint256 timestamp
    );

    event CommitmentVerified(
        uint256 indexed commitmentId,
        bool verified,
        uint256 timestamp
    );

    event ProposerAdded(address indexed proposer);
    event ProposerRemoved(address indexed proposer);

    // Structs
    struct Commitment {
        bytes32 stateRoot;
        uint256 blockNumber;
        bytes32 proofHash;
        address proposer;
        uint256 timestamp;
        bool verified;
        bool finalized;
    }

    struct ProofData {
        bytes32 proofHash;
        bytes proof;
        bytes32 publicInputs;
    }

    // State variables
    Counters.Counter private _commitmentIds;
    mapping(uint256 => Commitment) public commitments;
    mapping(address => bool) public proposers;
    mapping(bytes32 => bool) public verifiedProofs;

    // Configuration
    uint256 public minBlockInterval = 1800; // Minimum blocks between commitments
    uint256 public proofVerificationTimeout = 1 hours;
    uint256 public finalityDelay = 7 days;

    // Latest commitment info
    uint256 public latestCommitmentId;
    bytes32 public latestStateRoot;
    uint256 public latestBlockNumber;

    // Modifiers
    modifier onlyProposer() {
        require(proposers[msg.sender], "CommitmentStorage: caller is not a proposer");
        _;
    }

    modifier validBlockNumber(uint256 blockNumber) {
        require(blockNumber > latestBlockNumber, "CommitmentStorage: block number must be greater than latest");
        require(blockNumber - latestBlockNumber >= minBlockInterval, "CommitmentStorage: block interval too small");
        _;
    }

    constructor() {
        // Initialize with genesis state
        latestStateRoot = bytes32(0);
        latestBlockNumber = 0;
    }

    /**
     * @dev Submit a new commitment with ZK proof
     * @param stateRoot The state root to commit
     * @param blockNumber The L2 block number
     * @param proofData The ZK proof data
     */
    function submitCommitment(
        bytes32 stateRoot,
        uint256 blockNumber,
        ProofData calldata proofData
    ) external onlyProposer validBlockNumber(blockNumber) nonReentrant {
        require(stateRoot != bytes32(0), "CommitmentStorage: invalid state root");
        require(proofData.proof.length > 0, "CommitmentStorage: proof required");

        // Verify the proof (this would integrate with the actual ZK verifier)
        bool proofValid = verifyProof(proofData);
        require(proofValid, "CommitmentStorage: invalid proof");

        // Generate commitment ID
        _commitmentIds.increment();
        uint256 commitmentId = _commitmentIds.current();

        // Store commitment
        commitments[commitmentId] = Commitment({
            stateRoot: stateRoot,
            blockNumber: blockNumber,
            proofHash: proofData.proofHash,
            proposer: msg.sender,
            timestamp: block.timestamp,
            verified: true,
            finalized: false
        });

        // Update latest state
        latestCommitmentId = commitmentId;
        latestStateRoot = stateRoot;
        latestBlockNumber = blockNumber;

        // Mark proof as verified
        verifiedProofs[proofData.proofHash] = true;

        emit CommitmentSubmitted(
            commitmentId,
            stateRoot,
            blockNumber,
            proofData.proofHash,
            msg.sender,
            block.timestamp
        );

        emit CommitmentVerified(commitmentId, true, block.timestamp);
    }

    /**
     * @dev Verify if a transaction is committed
     * @param txHash The transaction hash to check
     * @param blockNumber The block number where the transaction was included
     * @return committed True if the transaction is committed
     * @return commitmentId The ID of the commitment that includes this transaction
     */
    // TODO: Implement
    function isTransactionCommitted(
        bytes32 txHash,
        uint256 blockNumber
    ) external view returns (bool committed, uint256 commitmentId) {
        // Find the commitment that includes this block
        for (uint256 i = latestCommitmentId; i > 0; i--) {
            Commitment storage commitment = commitments[i];
            if (commitment.blockNumber >= blockNumber && commitment.verified) {
                // In a real implementation, you would verify the transaction inclusion
                // using a Merkle proof or similar mechanism
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Get commitment details
     * @param commitmentId The commitment ID
     * @return The commitment data
     */
    function getCommitment(uint256 commitmentId) external view returns (Commitment memory) {
        require(commitmentId > 0 && commitmentId <= latestCommitmentId, "CommitmentStorage: invalid commitment ID");
        return commitments[commitmentId];
    }

    /**
     * @dev Get the latest commitment info
     * @return commitmentId The latest commitment ID
     * @return stateRoot The latest state root
     * @return blockNumber The latest block number
     */
    function getLatestCommitment() external view returns (
        uint256 commitmentId,
        bytes32 stateRoot,
        uint256 blockNumber
    ) {
        return (latestCommitmentId, latestStateRoot, latestBlockNumber);
    }

    /**
     * @dev Check if a proof hash has been verified
     * @param proofHash The proof hash to check
     * @return True if the proof has been verified
     */
    function isProofVerified(bytes32 proofHash) external view returns (bool) {
        return verifiedProofs[proofHash];
    }

    // Admin functions
    /**
     * @dev Add a new proposer
     * @param proposer The address to add as proposer
     */
    function addProposer(address proposer) external onlyOwner {
        require(proposer != address(0), "CommitmentStorage: invalid proposer address");
        require(!proposers[proposer], "CommitmentStorage: proposer already exists");

        proposers[proposer] = true;
        emit ProposerAdded(proposer);
    }

    /**
     * @dev Remove a proposer
     * @param proposer The address to remove as proposer
     */
    function removeProposer(address proposer) external onlyOwner {
        require(proposers[proposer], "CommitmentStorage: proposer does not exist");

        proposers[proposer] = false;
        emit ProposerRemoved(proposer);
    }

    /**
     * @dev Update configuration parameters
     * @param _minBlockInterval New minimum block interval
     * @param _proofVerificationTimeout New proof verification timeout
     * @param _finalityDelay New finality delay
     */
    function updateConfig(
        uint256 _minBlockInterval,
        uint256 _proofVerificationTimeout,
        uint256 _finalityDelay
    ) external onlyOwner {
        minBlockInterval = _minBlockInterval;
        proofVerificationTimeout = _proofVerificationTimeout;
        finalityDelay = _finalityDelay;
    }

    // Internal functions
    /**
     * @dev Verify a ZK proof (placeholder implementation)
     * In a real implementation, this would integrate with the actual ZK verifier
     * @param proofData The proof data to verify
     * @return True if the proof is valid
     */
    // TODO: Fix
    function verifyProof(ProofData calldata proofData) internal pure returns (bool) {
        // This is a placeholder implementation
        // In a real implementation, you would:
        // 1. Call the actual ZK verifier contract
        // 2. Verify the proof against the public inputs
        // 3. Return the verification result

        // For now, we'll accept all proofs (this should be replaced with actual verification)
        return true;
    }

    // View functions for external integration
    /**
     * @dev Get the total number of commitments
     * @return The total number of commitments
     */
    function getTotalCommitments() external view returns (uint256) {
        return latestCommitmentId;
    }

    /**
     * @dev Get commitment statistics
     * @return total Total number of commitments
     * @return verified Number of verified commitments
     * @return finalized Number of finalized commitments
     */
    function getCommitmentStats() external view returns (
        uint256 total,
        uint256 verified,
        uint256 finalized
    ) {
        total = latestCommitmentId;

        for (uint256 i = 1; i <= latestCommitmentId; i++) {
            Commitment storage commitment = commitments[i];
            if (commitment.verified) {
                verified++;
            }
            if (commitment.finalized) {
                finalized++;
            }
        }

        return (total, verified, finalized);
    }
}