pragma solidity 0.8.15;

import { VotingEscrow } from "../../src/oSushi/VotingEscrow.sol";
import { MockERC20 } from "../utils/MockERC20.sol";

contract VotingEscrowTest {
    VotingEscrow oSushi;
    MockERC20 Sushi;

    function setUp() public {
        Sushi = new MockERC20("Sushi", "SUSHI", 18);
        oSushi = new VotingEscrow(address(Sushi), "oSushi", "OSUSHI");
    }

    /* Basic Functionality Tests - Make sure functions execute */

    function test_create_lock() public {
        Sushi.mint(address(this), 1000 ether);
        Sushi.approve(address(oSushi), 1000 ether);

        uint initial_balance = oSushi.balanceOf(address(this));
        
        oSushi.createLock(1000 ether, 10 weeks);

        uint end_balance = oSushi.balanceOf(address(this));
       
        require(initial_balance < end_balance, "oSushi balance not updated");        
    }


    function test_lock_deposit() public {
        Sushi.mint(address(this), 1000 ether);
        Sushi.approve(address(oSushi), 1000 ether);

        uint initial_balance = oSushi.balanceOf(address(this));
        
        oSushi.createLock(1000 ether, 10 weeks);

        uint end_balance = oSushi.balanceOf(address(this));
       
        require(initial_balance < end_balance, "oSushi balance not updated");        
   
        // Once lock is established deposit into it

        initial_balance = end_balance;

        Sushi.mint(address(this), 1000 ether);
        Sushi.approve(address(oSushi), 1000 ether);

        oSushi.depositFor(address(this), 1000 ether);

        end_balance = oSushi.balanceOf(address(this));
        
        require(initial_balance < end_balance, "oSushi balance not updated");        
    }

    function test_totalSupply() public { 
        Sushi.mint(address(this), 1000 ether);
        Sushi.approve(address(oSushi), 1000 ether);
        
        oSushi.createLock(1000 ether, 10 weeks);

        uint end_balance = oSushi.balanceOf(address(this));

        uint total_supply = oSushi.totalSupply();

        require(end_balance == total_supply, "Total Supply Miscount");
    }

    function test_cancel() public {
        Sushi.mint(address(this), 1000 ether);
        Sushi.approve(address(oSushi), 1000 ether);

        oSushi.createLock(1000 ether, 10 weeks);
    
        oSushi.cancel();

        require(Sushi.balanceOf(address(this)) == 500 ether, "Improper Cancellation Fee");
    }

    // TODO: Tests for depositFor and IncreaseAmountFor using address impersenation

    /* Test Time Math, ensure Epochs are being counter properly */
}
