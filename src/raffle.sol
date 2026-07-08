// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title A sample raffle contract
 * @author Arnav
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
 */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    //**  Errors **/
    error Raffle__notEnoughEth();
    error Raffle__RewardNotTransferred();

    //  variable Declarations
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private immutable i_interval;
    // uint256 private immutable s_lastInterval;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // events
    event EnteredRaffle(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_lastTimeStamp = block.timestamp;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address winner = s_players[winnerIndex];
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__RewardNotTransferred();
        }
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEth();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
                i_gasLane,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbackGasLimit,
                NUM_WORDS
            );
        }
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
