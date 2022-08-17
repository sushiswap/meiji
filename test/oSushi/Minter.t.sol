pragma solidity 0.8.15;

import { MockERC20 } from "../utils/MockERC20.sol";
import { LiquidityGauge } from "../../src/oSushi/LiquidityGauge.sol";
import { Minter } from "../../src/oSushi/Minter.sol";

contract MockController {
    function gauge_types(address addr) external view returns (int128) {
        return 1;
    }
}

interface Cheatcodes {
    function prank(address, address) external;
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
    Cheatcodes vm;

    function setUp() public {
        MockController controller = new MockController();
        token = new MockERC20("TokenA", "A", 18);
        minter = new Minter(address(token), address(controller));
        vm = Cheatcodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    }

    function testMint() public {
        MockGauge gauge = new MockGauge();

        uint256 initial_balance = token.balanceOf(address(this));

        minter.mint(address(gauge));

        uint256 final_balance = token.balanceOf(address(this));
    
        require(final_balance > initial_balance, "Minting Failed");
    }

    /* TODO
    function testMintMany() public {
    } */

    function testMintFor() public {
        MockGauge gauge = new MockGauge();

        uint256 initial_balance = token.balanceOf(address(7));
    
        address test_context = address(this);

        vm.prank(address(7), address(7));
    
        minter.toggle_approve_mint(test_context);

        minter.mint_for(address(gauge), address(7));

        uint256 final_balance = token.balanceOf(address(7));

        require(final_balance > initial_balance, "Minting Failed");
    }
}
