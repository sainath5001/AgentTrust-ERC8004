// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {AgentTrust} from "../src/AgentTrust.sol";

/**
 * @title DeployAgentTrust
 * @notice Deployment script for AgentTrust contract on Ethereum Sepolia testnet
 * @dev Usage:
 *      forge script script/Deploy.s.sol:DeployAgentTrust --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 *
 *      Or with private key:
 *      forge script script/Deploy.s.sol:DeployAgentTrust --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
 */
contract DeployAgentTrust is Script {
    // Contract name and symbol
    string public constant AGENT_NAME = "AgentTrust Protocol";
    string public constant AGENT_SYMBOL = "ATRUST";

    function run() external {
        // Get deployer address
        address deployer = msg.sender;
        if (tx.origin != address(0)) {
            deployer = tx.origin;
        }

        console.log("Deploying AgentTrust contract...");
        console.log("Deployer address:", deployer);
        console.log("Network:", block.chainid);

        // Deploy contract
        vm.startBroadcast();

        AgentTrust agentTrust = new AgentTrust(AGENT_NAME, AGENT_SYMBOL);

        vm.stopBroadcast();

        // Log deployment information
        console.log("AgentTrust deployed at:", address(agentTrust));
        console.log("Contract name:", AGENT_NAME);
        console.log("Contract symbol:", AGENT_SYMBOL);
        console.log("Owner:", agentTrust.owner());
        console.log("Total agents:", agentTrust.getTotalAgents());

        // Verify deployment
        require(agentTrust.owner() == deployer, "Deployment verification failed: owner mismatch");
        require(agentTrust.getTotalAgents() == 0, "Deployment verification failed: initial agent count should be 0");

        console.log("Deployment successful!");
    }
}
