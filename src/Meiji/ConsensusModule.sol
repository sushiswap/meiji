pragma solidity 0.8.15;

// A Solidity (sadly) Implementation of a Democratic Voting Mechanism for the Meiji DAO
// By @ControlCplusControlV
/*
import "./libraries/ABDKMathQuad.sol";

contract DemocraticConsensusMechanism {

    struct Member {}

    struct Proposal {}

    enum Action {}

    private constant address ENTER_TOKEN = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2; // SUSHI in this case

    struct Parameters {
        uint48 VOTING_PERIOD,
        uint48 MAX_PROPOSALS_A_WEEK,
        uint48 SIGNAL_SHARE_THRESHOLD,
        uint8 ACTIONS_PER_WEEK,
        uint256 SHARE_QUROUM,
        uint256 TOTAL_MEMBERS
    }

    public Parameters parameters; 

    function enlist(uint256 token_commitment) public returns (uint112 shares_granted) {
        // First Check that they aren't already a Member
        // @dev TODO
        // Next transfer over the tokens
        IERC20(ENTER_TOKEN).transferFrom(msg.sender, token_commitment);

        // shares_granted is equal to sqrt(commitment) / log(sqrt(TOTAL_MEMBERs))
        // Since tokens use uint256 but math uses uint112, commitment tokens must be scaled down
        // TODO actually scale commit
        uint112 scaled_commitment = uint112(token_commitment);
        bytes16 numerator = ABDKMathQuad.sqrt(bytes16(scaled_commitment));
        bytes16 denominator = ABDKMathQuad.log(ABDKMathQuad.sqrt(parameters.TOTAL_MEMBERS));

        uint112 shares_granted = uint112(ABDKMathQuad.div(numerator, denominator));
    }

} */
