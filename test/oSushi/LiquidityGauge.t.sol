pragma solidity 0.8.15;

import { MockLP } from "../utils/MockLP.sol";
import { LiquidityGauge } from "../../src/oSushi/LiquidityGauge.sol";
import { Minter } from "../../src/oSushi/Minter.sol";

contract LiquidityGaugeUnitTests {
    MockLP pool;
    LiquidityGauge gauge;


    function setUp() public {
        pool = new MockLP();
    }
}
