pragma solidity 0.8.15;

import { VotingEscrow } "../../src/oSushi/VotingEscrow.sol";
import { MockERC20 } from "../utils/MockERC20.sol";

contract VotingEscrowTest {
    VotingEscrow oSushi;
    MockERC20 Sushi;

    function setUp() public {
        Sushi = new MockERC20("Sushi", "SUSHI", 18);
        oSushi = new VotingEscrow(address(Sushi), "oSushi", "OSUSHI");
    }
}
