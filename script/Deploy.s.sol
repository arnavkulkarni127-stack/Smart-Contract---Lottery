// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./helperConfig.s.sol";
import {Raffle} from "../src/raffle.sol";

contract DeployRaffle is Script, HelperConfig {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.vrfCoordinator
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
