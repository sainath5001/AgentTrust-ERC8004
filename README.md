# AgentTrust - ERC-8004 Protocol

A Foundry-based Solidity implementation of the ERC-8004 (Trustless Agent Identity + Reputation) protocol. This project provides a decentralized system for registering autonomous service agents as ERC721 NFTs and managing their on-chain reputation through a rating system.

## Overview

AgentTrust implements a simplified ERC-8004 protocol with the following features:

- **Agent Identity Registry**: Each agent is minted as an ERC721 NFT with metadata URI
- **Reputation System**: Users can submit ratings (1-5) for registered agents
- **Double-Rating Prevention**: Each address can only rate an agent once
- **On-Chain Reputation Tracking**: Total ratings and average scores are stored on-chain

## Project Structure

```
AgentTrust-ERC8004/
├── src/
│   └── AgentTrust.sol          # Main ERC-8004 contract
├── test/
│   └── AgentTrust.t.sol        # Comprehensive test suite
├── script/
│   └── Deploy.s.sol            # Deployment script for Sepolia
├── lib/                         # OpenZeppelin dependencies
├── foundry.toml                 # Foundry configuration
└── README.md                    # This file
```

## Features

### 1. Agent Identity Registry
- Agents are represented as ERC721 NFTs
- Each agent stores:
  - Creator address
  - Metadata URI for agent profile
  - Owner address (ERC721 owner)
- Emits `AgentRegistered` event on registration

### 2. Reputation System
- Users can submit ratings from 1-5
- Prevents same address from rating the same agent twice
- Tracks total ratings and calculates average score
- Average score is returned with 2 decimal precision (multiplied by 100)
- Emits `RatingSubmitted` event on each rating

### 3. Security Features
- ReentrancyGuard protection
- Input validation for ratings
- Custom errors for gas efficiency
- Prevents agents from rating themselves
- Access control using OpenZeppelin's Ownable

## Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.26

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd AgentTrust-ERC8004
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

## Usage

### Testing

Run all tests:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vv
```

Run specific test:
```bash
forge test --match-test test_RegisterAgent -vv
```

### Test Coverage

The test suite includes:
- ✅ Agent registration
- ✅ Rating submission
- ✅ Double-rating prevention
- ✅ Average calculation
- ✅ Edge cases and error handling
- ✅ ERC721 functionality

All 25 tests pass successfully.

## Deployment

### Deploy to Sepolia Testnet

1. Set up environment variables:
```bash
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_INFURA_KEY"
export PRIVATE_KEY="your_private_key"
export ETHERSCAN_API_KEY="your_etherscan_api_key"  # For verification
```

2. Deploy the contract:
```bash
forge script script/Deploy.s.sol:DeployAgentTrust \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv
```

### Alternative: Using .env file

Create a `.env` file:
```
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Then deploy:
```bash
source .env
forge script script/Deploy.s.sol:DeployAgentTrust \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv
```

## Contract Interface

### Core Functions

#### `registerAgent(address to, string memory metadataURI)`
Registers a new agent and mints an ERC721 NFT.

#### `submitRating(uint256 agentId, uint8 rating)`
Submits a rating (1-5) for an agent. Prevents double rating.

#### `getAgentDetails(uint256 agentId)`
Returns agent owner, creator, and metadata URI.

#### `getReputationSummary(uint256 agentId)`
Returns total ratings and average score (multiplied by 100).

#### `getAverageRating(uint256 agentId)`
Returns the average rating as a decimal (multiplied by 100).

#### `hasAddressRated(uint256 agentId, address rater)`
Checks if an address has rated a specific agent.

### Events

- `AgentRegistered(uint256 indexed agentId, address indexed creator, string metadataURI)`
- `RatingSubmitted(uint256 indexed agentId, address indexed rater, uint8 rating, uint256 newAverage)`

### Custom Errors

- `InvalidRating(uint8 rating)` - Rating is not between 1-5
- `AgentNotFound(uint256 agentId)` - Agent doesn't exist
- `AlreadyRated(uint256 agentId, address rater)` - Address already rated this agent
- `CannotRateOwnAgent(uint256 agentId)` - Agent owner cannot rate their own agent

## Architecture

The contract uses:
- **ERC721** from OpenZeppelin for NFT functionality
- **Ownable** from OpenZeppelin for access control
- **ReentrancyGuard** from OpenZeppelin for security
- Custom errors for gas-efficient error handling
- NatSpec comments for documentation

## Gas Optimization

- Uses custom errors instead of require strings
- Efficient storage layout
- Minimal external calls
- ReentrancyGuard only where necessary

## Security Considerations

- ✅ Reentrancy protection on rating function
- ✅ Input validation for all parameters
- ✅ Prevents double rating
- ✅ Prevents self-rating
- ✅ Uses OpenZeppelin's battle-tested contracts
- ✅ Follows checks-effects-interactions pattern

## License

MIT

## Contributing

This is a simplified implementation of ERC-8004. For production use, consider:
- Additional access control mechanisms
- Governance features
- Slashing mechanisms for malicious agents
- Time-weighted reputation
- Reputation decay mechanisms

## References

- [ERC-8004 Specification](https://eips.ethereum.org/EIPS/eip-8004)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Foundry Documentation](https://book.getfoundry.sh/)
