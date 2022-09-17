pragma solidity 0.8.15;

// A Solidity Mock Implementation of the Meiji DAO
// By @ControlCplusControlV

import "../libraries/ABDKMathQuad.sol";

contract MeijiGovernanceHouse {

    // Modified MolochDAO Member Struct
    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated 
        bool exists; // always true once a member has been created
        bool jailed; // determines whether someone has been kicked from the DAO
        uint256 joined; // Maybe reduce this size to pack into the struct
        uint256 shares; // the # of voting shares assigned to this member
        uint256 bond_size; // tokens locked up to join
    }

    struct Proposal {

    }

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

    public mapping(address => Member) MemberRegistry;

    function enlist(uint256 token_commitment, address _delegateKey) external returns (uint112 shares_granted) {
        // First Check that they aren't already a Member
        require(!MemberRegistry[msg.sender].exists);
        // Next transfer over the tokens
        IERC20(ENTER_TOKEN).transferFrom(msg.sender, token_commitment);
        // shares_granted is equal to sqrt(commitment) / log(sqrt(TOTAL_MEMBERs))
        // Since tokens use uint256 but math uses uint112, commitment tokens must be scaled down
        uint112 scaled_commitment = uint112(token_commitment);
        bytes16 numerator = ABDKMathQuad.sqrt(bytes16(scaled_commitment));
        bytes16 denominator = ABDKMathQuad.log(ABDKMathQuad.sqrt(parameters.TOTAL_MEMBERS));

        uint112 shares_granted = uint112(ABDKMathQuad.div(numerator, denominator));
    
        Member memory newMember = new Member({
            delegateKey : _delegateKey, 
            exists: true,
            joined: block.timestamp,
            jailed: false,
            bond_size: token_commitment,
            shares: shares_granted
        });

        MemberRegistry[msg.sender] = newMember;
        
        // implicit return
    }

    function rage_quit() external {
        require(MemberRegistry[msg.sender].exists);

        Member memory newMember = MemberRegistry[msg.sender];
    
        uint256 bond = newMember.bond_size;

        delete MemberRegistry[msg.sender];

        if (newMember.jailed) {
            Member memory newMember = new Member({
                delegateKey : _delegateKey, 
                exists: true,
                joined: 0,
                jailed: true,
                bond_size: 0,
                shares: 0
            });

            MemberRegistry[msg.sender] = newMember;
        }

        IERC20(ENTER_TOKEN).transfer(msg.sender, bond);
    }

}
