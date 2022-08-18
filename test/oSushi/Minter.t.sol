pragma solidity 0.8.15;

import {MockERC20} from "../utils/MockERC20.sol";
import {LiquidityGauge} from "../../src/oSushi/LiquidityGauge.sol";
import {Minter} from "../../src/oSushi/Minter.sol";

contract MockController {
    function gaugeTypes(address addr) external view returns (int128) {
        return 1;
    }
}

interface Cheatcodes {
    function prank(address, address) external;
}

contract MockGauge {
    uint256 fraction = 100;

    function setFraction(uint256 newFraction) external {
        fraction = newFraction;
    }

    function integrateFraction(address addr) external view returns (uint256) {
        return fraction;
    }

    function userCheckpoint(address addr) external returns (bool) {
        return true;
    }
}

contract MockMasterChef {
    address token;

    constructor(address _token) {
        token = _token;
    }

    function deposit(uint256, uint256 _amount) external {
        MockERC20(token).mint(msg.sender, 100);
    }
}

contract MinterUnitTest {
    Minter minter;
    MockERC20 token;
    MockMasterChef masterChef;
    Cheatcodes vm;

    function setUp() public {
        MockController controller = new MockController();
        token = new MockERC20("TokenA", "A", 18);
        masterChef = new MockMasterChef(address(token));
        minter = new Minter(
            address(masterChef),
            0,
            address(token),
            address(controller)
        );
        minter.initialize();
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

        minter.mintFor(address(gauge), address(7));

        uint256 final_balance = token.balanceOf(address(7));

        require(final_balance > initial_balance, "Minting Failed");
    }
}
