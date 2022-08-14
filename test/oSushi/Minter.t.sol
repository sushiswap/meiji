pragma solidity 0.8.15;

import { MockERC20 } from "../utils/MockERC20.sol";
import { LiquidityGauge } from "../../src/oSushi/LiquidityGauge.sol";
import { Minter } from "../../src/oSushi/Minter.sol";

contract MockController {
    function gauge_types(address addr) external view returns (int128) {
        return 1;
    }
}

contract MockGauge {
    uint256 fraction = 100;

    function setFraction(uint256 new_fraction) external {
        fraction = new_fraction;
    }

    function integrate_fraction(address addr) external view returns (uint256) {
        return fraction;
    }

    function user_checkpoint(address addr) external returns (bool) {
        return true;
    }
}

contract MinterUnitTest {
    Minter minter;
    MockERC20 token;

    function setUp() public {
        MockController controller = new MockController();
        token = new MockERC20("TokenA", "A", 18);
        minter = new Minter(address(token), address(controller));
    }

    function testMint() public {
        MockGauge gauge = new MockGauge();

        uint256 initial_balance = token.balanceOf(address(this));

        minter.mint(address(gauge));

        uint256 final_balance = token.balanceOf(address(this));
    
        require(final_balance > initial_balance, "Minting Failed");
    }

    function testMintMany() public {

    }

    function testMintFor() public {}
}
