// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AgentTrust} from "../src/AgentTrust.sol";

/**
 * @title AgentTrustTest
 * @notice Comprehensive test suite for ERC-8004 AgentTrust contract
 */
contract AgentTrustTest is Test {
    AgentTrust public agentTrust;

    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public agentOwner;

    string public constant AGENT_NAME = "AgentTrust Protocol";
    string public constant AGENT_SYMBOL = "ATRUST";
    string public constant METADATA_URI = "https://example.com/agent/1";

    event AgentRegistered(uint256 indexed agentId, address indexed creator, string metadataURI);

    event RatingSubmitted(uint256 indexed agentId, address indexed rater, uint8 rating, uint256 newAverage);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        agentOwner = makeAddr("agentOwner");

        agentTrust = new AgentTrust(AGENT_NAME, AGENT_SYMBOL);
    }

    // ============ Agent Registration Tests ============

    function test_RegisterAgent() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        assertEq(agentId, 0);
        assertEq(agentTrust.ownerOf(agentId), agentOwner);
        assertEq(agentTrust.tokenURI(agentId), METADATA_URI);
        assertEq(agentTrust.getTotalAgents(), 1);
    }

    function test_RegisterAgent_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit AgentRegistered(0, owner, METADATA_URI);

        agentTrust.registerAgent(agentOwner, METADATA_URI);
    }

    function test_RegisterAgent_StoresCreator() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        (address ownerAddr, address creator, string memory uri) = agentTrust.getAgentDetails(agentId);

        assertEq(ownerAddr, agentOwner);
        assertEq(creator, owner);
        assertEq(uri, METADATA_URI);
    }

    function test_RegisterMultipleAgents() public {
        uint256 agentId1 = agentTrust.registerAgent(agentOwner, METADATA_URI);
        uint256 agentId2 = agentTrust.registerAgent(user1, "https://example.com/agent/2");

        assertEq(agentId1, 0);
        assertEq(agentId2, 1);
        assertEq(agentTrust.getTotalAgents(), 2);
    }

    function test_RegisterAgent_RevertIfZeroAddress() public {
        vm.expectRevert();
        agentTrust.registerAgent(address(0), METADATA_URI);
    }

    // ============ Rating Tests ============

    function test_SubmitRating() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);

        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 1);
        assertEq(averageScore, 500); // 5.00 * 100
    }

    function test_SubmitRating_EmitsEvent() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.expectEmit(true, true, false, true);
        emit RatingSubmitted(agentId, user1, 5, 500);

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);
    }

    function test_SubmitRating_CalculatesAverage() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        // User1 rates 5
        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);

        // User2 rates 4
        vm.prank(user2);
        agentTrust.submitRating(agentId, 4);

        // User3 rates 3
        vm.prank(user3);
        agentTrust.submitRating(agentId, 3);

        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 3);
        assertEq(averageScore, 400); // (5+4+3)/3 = 4.00 * 100 = 400
    }

    function test_SubmitRating_PreventsDoubleRating() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.AlreadyRated.selector, agentId, user1));
        agentTrust.submitRating(agentId, 4);
    }

    function test_SubmitRating_PreventsRatingOwnAgent() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(agentOwner);
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.CannotRateOwnAgent.selector, agentId));
        agentTrust.submitRating(agentId, 5);
    }

    function test_SubmitRating_RevertIfInvalidRating_TooLow() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.InvalidRating.selector, 0));
        agentTrust.submitRating(agentId, 0);
    }

    function test_SubmitRating_RevertIfInvalidRating_TooHigh() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.InvalidRating.selector, 6));
        agentTrust.submitRating(agentId, 6);
    }

    function test_SubmitRating_RevertIfAgentNotFound() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.AgentNotFound.selector, 999));
        agentTrust.submitRating(999, 5);
    }

    function test_SubmitRating_AllValidRatings() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        // Test all valid ratings (1-5)
        for (uint8 i = 1; i <= 5; i++) {
            address rater = makeAddr(string(abi.encodePacked("rater", i)));
            vm.prank(rater);
            agentTrust.submitRating(agentId, i);
        }

        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 5);
        assertEq(averageScore, 300); // (1+2+3+4+5)/5 = 3.00 * 100 = 300
    }

    // ============ Read Function Tests ============

    function test_GetAgentDetails() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        (address ownerAddr, address creator, string memory uri) = agentTrust.getAgentDetails(agentId);

        assertEq(ownerAddr, agentOwner);
        assertEq(creator, owner);
        assertEq(uri, METADATA_URI);
    }

    function test_GetAgentDetails_RevertIfAgentNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.AgentNotFound.selector, 999));
        agentTrust.getAgentDetails(999);
    }

    function test_GetReputationSummary_NoRatings() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 0);
        assertEq(averageScore, 0);
    }

    function test_GetReputationSummary_WithRatings() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);
        vm.prank(user2);
        agentTrust.submitRating(agentId, 3);

        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 2);
        assertEq(averageScore, 400); // (5+3)/2 = 4.00 * 100 = 400
    }

    function test_GetReputationSummary_RevertIfAgentNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(AgentTrust.AgentNotFound.selector, 999));
        agentTrust.getReputationSummary(999);
    }

    function test_GetAverageRating() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);
        vm.prank(user2);
        agentTrust.submitRating(agentId, 3);

        uint256 average = agentTrust.getAverageRating(agentId);
        assertEq(average, 400); // 4.00 * 100
    }

    function test_HasAddressRated() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        assertFalse(agentTrust.hasAddressRated(agentId, user1));

        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);

        assertTrue(agentTrust.hasAddressRated(agentId, user1));
        assertFalse(agentTrust.hasAddressRated(agentId, user2));
    }

    function test_GetTotalAgents() public {
        assertEq(agentTrust.getTotalAgents(), 0);

        agentTrust.registerAgent(agentOwner, METADATA_URI);
        assertEq(agentTrust.getTotalAgents(), 1);

        agentTrust.registerAgent(user1, "https://example.com/agent/2");
        assertEq(agentTrust.getTotalAgents(), 2);
    }

    // ============ Edge Cases ============

    function test_MultipleAgents_MultipleRatings() public {
        // Register multiple agents
        uint256 agentId1 = agentTrust.registerAgent(agentOwner, METADATA_URI);
        uint256 agentId2 = agentTrust.registerAgent(user1, "https://example.com/agent/2");

        // Rate agent1
        vm.prank(user1);
        agentTrust.submitRating(agentId1, 5);
        vm.prank(user2);
        agentTrust.submitRating(agentId1, 4);

        // Rate agent2
        vm.prank(agentOwner);
        agentTrust.submitRating(agentId2, 3);
        vm.prank(user2);
        agentTrust.submitRating(agentId2, 5);

        // Verify agent1 reputation
        (uint256 total1, uint256 avg1) = agentTrust.getReputationSummary(agentId1);
        assertEq(total1, 2);
        assertEq(avg1, 450); // (5+4)/2 = 4.50 * 100

        // Verify agent2 reputation
        (uint256 total2, uint256 avg2) = agentTrust.getReputationSummary(agentId2);
        assertEq(total2, 2);
        assertEq(avg2, 400); // (3+5)/2 = 4.00 * 100
    }

    function test_RatingPrecision() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        // Submit ratings that result in non-integer average
        vm.prank(user1);
        agentTrust.submitRating(agentId, 5);
        vm.prank(user2);
        agentTrust.submitRating(agentId, 4);
        vm.prank(user3);
        agentTrust.submitRating(agentId, 4);

        // (5+4+4)/3 = 4.33... * 100 = 433 (rounded down)
        (uint256 totalRatings, uint256 averageScore) = agentTrust.getReputationSummary(agentId);

        assertEq(totalRatings, 3);
        assertEq(averageScore, 433); // 13/3 * 100 = 433.33... -> 433
    }

    function test_ERC721Functionality() public {
        uint256 agentId = agentTrust.registerAgent(agentOwner, METADATA_URI);

        // Test ERC721 standard functions
        assertEq(agentTrust.ownerOf(agentId), agentOwner);
        assertEq(agentTrust.balanceOf(agentOwner), 1);
        assertEq(agentTrust.tokenURI(agentId), METADATA_URI);
    }
}
