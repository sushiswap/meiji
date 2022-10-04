pragma solidity ^0.8.16;

import "./util/ERC20.sol";
import {MasterDeployer} from "../src/MeijiPools/MasterDeployer.sol";
import "../src/MeijiPools/ConcentratedLiquidityPool.sol";
import "../src/MeijiPools/ConcentratedLiquidityPoolFactory.sol";

import "../src/MeijiPools/interfaces/IPositionManager.sol";

import "../src/MeijiPools/libraries/Ticks.sol";
import "../src/MeijiPools/libraries/TickMath.sol";
import "../src/MeijiPools/libraries/TridentMath.sol";

interface VM {
    function assume(bool) external;
}

contract FuzzySushiHelpers is IPositionManager {
    ERC20 tokenA;
    ERC20 tokenB;

    MasterDeployer master_deployer;
    ConcentratedLiquidityPoolFactory pool_deployer;

    address constant private VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    VM vm = VM(VM_ADDRESS);

    function getPool(uint24 swapFee, uint160 price, uint24 tickSpacing) public returns (ConcentratedLiquidityPool pool){
        bytes memory deploy_data = abi.encode(address(tokenA), address(tokenB), swapFee, price, tickSpacing);

        pool = ConcentratedLiquidityPool(pool_deployer.deployPool(deploy_data));
    }

    function mintCallback(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        bool native
    ) external {
        ERC20(token0).transfer(msg.sender, amount0);
        ERC20(token1).transfer(msg.sender, amount1);
    }

    struct RandomizedLiquidityPool {
        uint128 reserve0;
        uint128 reserve1;
        uint24 swapFee;
    }

    function getRandomizedPoolWithLiquidity(RandomizedLiquidityPool calldata pool) internal returns (ConcentratedLiquidityPool) {
        uint24 swapFee = pool.swapFee;
        uint128 reserve0 = pool.reserve0;
        uint128 reserve1 = pool.reserve1;

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

        return pool;
    }
}