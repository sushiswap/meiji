pragma solidity ^0.8.16;

import "./util/ERC20.sol";
import {MasterDeployer} from "../src/MeijiPools/MasterDeployer.sol";
import "../src/MeijiPools/ConcentratedLiquidityPool.sol";
import "../src/MeijiPools/ConcentratedLiquidityPoolFactory.sol";

import "../src/MeijiPools/interfaces/IPositionManager.sol";

import "../src/MeijiPools/libraries/Ticks.sol";
import "../src/MeijiPools/libraries/TickMath.sol";
import "../src/MeijiPools/libraries/TridentMath.sol";

import "./FuzzySushiHelpers.sol";

contract SwappingTests is IPositionManager, FuzzySushiHelpers {
    function setUp() public {
        master_deployer = new MasterDeployer(100, address(this));
        pool_deployer = new ConcentratedLiquidityPoolFactory(address(master_deployer));

        tokenA = new ERC20("TokenA", "A", 18);
        tokenB = new ERC20("TokenB", "B", 18);
    }


    function test_addLiquidity(uint24 swapFee, uint128 reserve0, uint128 reserve1) public {
        vm.assume(reserve0 > 1000);
        vm.assume(reserve1 > 1000);
        vm.assume(swapFee < 100000); // SwapFee must be below MAX Fee of 10%
        uint24 tickSpacing = 15;

        vm.assume(tickSpacing > 0 && tickSpacing < 443637);

        uint128 MAX_TICK_LIQUIDITY = Ticks.getMaxLiquidity(uint24(tickSpacing));


        tokenA.mint(address(this), reserve0);
        tokenB.mint(address(this), reserve1);

        IConcentratedLiquidityPoolStruct.MintParams memory params = IConcentratedLiquidityPoolStruct.MintParams({
            lowerOld: TickMath.MIN_TICK,
            lower: -30,
            upperOld: -30,
            upper: 105,
            amount0Desired: reserve0,
            amount1Desired: reserve1,
            native: false
        });

        uint160 price = uint160(TridentMath.sqrt(reserve1/reserve0) * (2 ** 96));

        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(-30));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(105));

        uint256 liquidity = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            price,
            uint256(reserve1),
            uint256(reserve0)
        ); 

        // Price level validations
        // Values are MIN_SQRT_RATION and MAX_SQRT_RATIO
        vm.assume(price > 4295128739 && price < 1461446703485210103287273052203988822378723970342);

        // Validate reserves again
        vm.assume(liquidity < MAX_TICK_LIQUIDITY);

        ConcentratedLiquidityPool pool = getPool(swapFee, price, tickSpacing);

        uint256 out = pool.mint(params);
        require(out > 0);
    }
}
