pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CommitmentStorage.sol";

contract CommitmentStorageTest is Test {
    CommitmentStorage public commitmentStorage;
    address public proposer;
    address public user;

    // Test data
    bytes32 public constant TEST_STATE_ROOT = bytes32(uint256(1));
    bytes32 public constant TEST_PROOF_HASH = bytes32(uint256(2));
    bytes public constant TEST_PROOF = hex"1234567890abcdef";
    bytes32 public constant TEST_PUBLIC_INPUTS = bytes32(uint256(3));

    function setUp() public {
        proposer = makeAddr("proposer");
        user = makeAddr("user");

        // Deploy contract
        commitmentStorage = new CommitmentStorage();

        // Add proposer
        commitmentStorage.addProposer(proposer);
    }

    function testDeploy() public {
        assertEq(commitmentStorage.owner(), address(this));
        assertTrue(commitmentStorage.proposers(proposer));
        assertEq(commitmentStorage.getTotalCommitments(), 0);
    }

    function testSubmitCommitment() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();

        // Verify commitment was stored
        assertEq(commitmentStorage.getTotalCommitments(), 1);
        assertEq(commitmentStorage.latestCommitmentId(), 1);
        assertEq(commitmentStorage.latestStateRoot(), TEST_STATE_ROOT);
        assertEq(commitmentStorage.latestBlockNumber(), 1800);

        // Get commitment details
        CommitmentStorage.Commitment memory commitment = commitmentStorage.getCommitment(1);
        assertEq(commitment.stateRoot, TEST_STATE_ROOT);
        assertEq(commitment.blockNumber, 1800);
        assertEq(commitment.proofHash, TEST_PROOF_HASH);
        assertEq(commitment.proposer, proposer);
        assertTrue(commitment.verified);
        assertFalse(commitment.finalized);
    }

    function testSubmitCommitmentUnauthorized() public {
        vm.startPrank(user);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        vm.expectRevert("CommitmentStorage: caller is not a proposer");
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();
    }

    function testSubmitCommitmentInvalidBlockNumber() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Try to submit with block number 0 (should fail)
        vm.expectRevert("CommitmentStorage: block number must be greater than latest");
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            0,
            proofData
        );

        vm.stopPrank();
    }

    function testSubmitCommitmentBlockIntervalTooSmall() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Submit first commitment
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        // Try to submit second commitment with too small interval
        vm.expectRevert("CommitmentStorage: block interval too small");
        commitmentStorage.submitCommitment(
            bytes32(uint256(2)),
            3599, // Should be < 1800 + 1800 = 3600
            proofData
        );

        vm.stopPrank();
    }

    function testIsTransactionCommitted() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Submit commitment
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();

        // Check if transaction is committed
        (bool committed, uint256 commitmentId) = commitmentStorage.isTransactionCommitted(
            bytes32(uint256(123)), // txHash
            1800 // blockNumber
        );

        assertTrue(committed);
        assertEq(commitmentId, 1);
    }

    function testGetLatestCommitment() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Submit commitment
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();

        // Get latest commitment
        (uint256 commitmentId, bytes32 stateRoot, uint256 blockNumber) = commitmentStorage.getLatestCommitment();

        assertEq(commitmentId, 1);
        assertEq(stateRoot, TEST_STATE_ROOT);
        assertEq(blockNumber, 1800);
    }

    function testAddAndRemoveProposer() public {
        address newProposer = makeAddr("newProposer");

        // Add proposer
        commitmentStorage.addProposer(newProposer);
        assertTrue(commitmentStorage.proposers(newProposer));

        // Remove proposer
        commitmentStorage.removeProposer(newProposer);
        assertFalse(commitmentStorage.proposers(newProposer));
    }

    function testUpdateConfig() public {
        uint256 newMinBlockInterval = 3600;
        uint256 newProofVerificationTimeout = 2 hours;
        uint256 newFinalityDelay = 14 days;

        commitmentStorage.updateConfig(
            newMinBlockInterval,
            newProofVerificationTimeout,
            newFinalityDelay
        );

        assertEq(commitmentStorage.minBlockInterval(), newMinBlockInterval);
        assertEq(commitmentStorage.proofVerificationTimeout(), newProofVerificationTimeout);
        assertEq(commitmentStorage.finalityDelay(), newFinalityDelay);
    }

    function testGetCommitmentStats() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Submit commitment
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();

        // Get stats
        (uint256 total, uint256 verified, uint256 finalized) = commitmentStorage.getCommitmentStats();

        assertEq(total, 1);
        assertEq(verified, 1);
        assertEq(finalized, 0);
    }

    function testIsProofVerified() public {
        vm.startPrank(proposer);

        CommitmentStorage.ProofData memory proofData = CommitmentStorage.ProofData({
            proofHash: TEST_PROOF_HASH,
            proof: TEST_PROOF,
            publicInputs: TEST_PUBLIC_INPUTS
        });

        // Submit commitment
        commitmentStorage.submitCommitment(
            TEST_STATE_ROOT,
            1800,
            proofData
        );

        vm.stopPrank();

        // Check if proof is verified
        assertTrue(commitmentStorage.isProofVerified(TEST_PROOF_HASH));
        assertFalse(commitmentStorage.isProofVerified(bytes32(uint256(999))));
    }
}