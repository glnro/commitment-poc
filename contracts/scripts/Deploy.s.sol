pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CommitmentStorage.sol";

/**
 * @title DeployCommitmentStorage
 * @dev Deployment script for the CommitmentStorage contract
 */
contract DeployCommitmentStorage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the CommitmentStorage contract
        CommitmentStorage commitmentStorage = new CommitmentStorage();

        console.log("CommitmentStorage deployed at:", address(commitmentStorage));
        console.log("Deployer:", deployer);

        // Add the deployer as the first proposer
        commitmentStorage.addProposer(deployer);
        console.log("Added deployer as proposer");

        vm.stopBroadcast();

        // Save deployment info
        string memory deploymentInfo = string.concat(
            "CommitmentStorage deployed at: ",
            vm.toString(address(commitmentStorage)),
            "\nDeployer: ",
            vm.toString(deployer),
            "\nNetwork: ",
            vm.toString(block.chainid)
        );

        vm.writeFile("deployment.txt", deploymentInfo);
        console.log("Deployment info saved to deployment.txt");
    }
}