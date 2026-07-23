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
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    //**  Errors **/
    error Raffle__notEnoughEth();
    error Raffle__RewardNotTransferred();
    error Raffle__CalculatingWinner();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 playerLength,
        uint256 raffleState
    );

    // type declarations
    enum RaffleState {
        open,
        closed
    }

    //  variable Declarations
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    // uint256 private immutable s_lastInterval;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players;
    RaffleState private s_raffleState = RaffleState.closed;
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
        s_raffleState = RaffleState.open;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEth();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__RewardNotTransferred();
        }
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.open;
    }

    /**
     * @dev
     * @param null
     * @return
     * @return
     */
    function checkUpkeep(
        bytes calldata
    ) public view returns (bool, bytes memory) {
        bool isOpen = RaffleState.open == s_raffleState;
        bool isTime = block.timestamp - s_lastTimeStamp >= i_interval;
        bool hasPlayers = s_players.length != 0;
        bool hasBalance = address(this).balance > 0;
        bool upKeepNeeded = isOpen && isTime && hasPlayers && hasBalance;
        return (upKeepNeeded, "");
    }

    function performUpkeep(bytes calldata performData) external {
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_raffleState = RaffleState.closed;
        if (s_raffleState != RaffleState.open) {
            revert Raffle__CalculatingWinner();
        }
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
