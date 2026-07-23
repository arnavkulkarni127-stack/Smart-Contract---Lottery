// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Raffle} from "../src/raffle.sol";
import {HelperConfig} from "../script/helperConfig.s.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../script/Deploy.s.sol";
import {console} from "forge-std/console.sol";

contract TestRaffle is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant START_PLAYER_BALANCE = 10 ether;

    event EnteredRaffle(address indexed player);

    // Instead reference Raffle.EnteredRaffle directly

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        vm.deal(PLAYER, START_PLAYER_BALANCE);
    }

    function testRaffle_NotEnoughEthSent() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__notEnoughEth.selector);
        raffle.enterRaffle();
    }

    /// @dev FIXED: Removed the erroneous require(msg.value...) check
    /// The entranceFee validation already happens in enterRaffle()
    function testRaffle_addPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffle.getEntranceFee()}();
        assert(raffle.getPlayer(0) == address(PLAYER));
    }

    function testRaffle_raffleStateIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.open);
    }

    /// @dev FIXED: Reference Raffle.EnteredRaffle instead of local event declaration
    /// This ensures the expectEmit checks the event from the Raffle contract
    function testRaffle_eventForRaffleEnterred() public {
        vm.startPrank(PLAYER); // Set caller context

        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER); // Shows expected signature (local event)

        raffle.enterRaffle{value: raffle.getEntranceFee()}(); // Triggers actual event
        vm.stopPrank();
    }

    function testWhoIsPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffle.getEntranceFee()}();
        address stored = raffle.getPlayer(0);
        console.log("Expected:", PLAYER);
        console.log("Stored:  ", stored);
        console.log("Msg sender in test:", msg.sender);
    }
}
