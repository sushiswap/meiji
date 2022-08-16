pragma solidity 0.8.15;

// End to End oSushi tests, seeing how they work against existing Sushi 
// Contracts and ensuring the system hums along

// Sushi V1 Contracts oSushi needs to interact with
//import { SushiToken } from "../src/SushiV1/SushiToken.sol";

import { MockLP } from "./utils/MockLP.sol";

// oSushi Contracts
import { GaugeController } from "../src/oSushi/GaugeController.sol";
import { LiquidityGauge } from "../src/oSushi/LiquidityGauge.sol";
import { Minter } from "../src/oSushi/Minter.sol";
import { VotingEscrow } from "../src/oSushi/VotingEscrow.sol";

contract oSushiTest { 
    address constant SUSHI = address(0);

    GaugeController controller;
    LiquidityGauge gauge;
    Minter minter;
    VotingEscrow escrow;

    /*
    function setUp() public {
        escrow = new VotingEscrow(address(SUSHI), "oSushi", "OSUSHI");
        controller = new GaugeController(address(escrow));
        minter = new Minter(address(SUSHI), address(controller));
    }

    function test_registerLP() public {}

    function test_emissionsCurve() public {}
    */
}
