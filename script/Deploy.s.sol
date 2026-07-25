// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./helperConfig.s.sol";
import {Raffle} from "../src/raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract DeployRaffle is Script, HelperConfig {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getConfig();
        CreateSubscription createSubId = new CreateSubscription();
        if (config.subscriptionId == 0) {
            config.subscriptionId = createSubId.createSubscription(
                config.vrfCoordinator
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link
            );
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.vrfCoordinator
        );
        VRFCoordinatorV2Mock(config.vrfCoordinator).addConsumer(
            config.subscriptionId,
            address(raffle)
        );

        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
