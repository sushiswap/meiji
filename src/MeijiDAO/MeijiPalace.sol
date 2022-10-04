// SPDX-License-Identifier: AGPL-3.0-only
// Thanks to @fullyallocated for his extensive help on this
pragma solidity 0.8.15;

// The Governance Policy submits & activates instructions in a INSTR module

import { MeijiInstructions } from "./modules/INSTR.sol";
import { MeijiVotes } from "./modules/VOTES.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import "./Kernel.sol";

error NotEnoughVotesToPropose();

error WarmupNotCompleted();
error NotAuthorized();
error UnableToActivate();
error SubmittedProposalHasExpired();

error ProposalAlreadyActivated();
error ProposalIsNotActive();

error UserAlreadyVoted();
error DepositedAfterActivation();
error PastVotingPeriod();

error ExecutorNotSubmitter();
error NotEnoughVotesToExecute();
error ProposalAlreadyExecuted();
error ExecutionTimelockStillActive();
error ExecutionWindowExpired(); 

error UnmetCollateralDuration();
error CollateralAlreadyReturned();


struct ProposalMetadata {
    address submitter;
    uint256 submissionTimestamp; 
    uint256 collateralAmt;
    uint256 activationTimestamp;
    uint256 totalRegisteredVotes;
    uint256 yesVotes;
    uint256 noVotes;
    bool isExecuted;
    bool isCollateralReturned;
    mapping(address => uint256) votesCastByUser;
}

/// @notice MeijiGovernance
/// @dev The Governor Policy is also the Kernel's Executor.
contract MeijiPalance is Policy {
    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Policy Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////

    MeijiInstructions public INSTR;
    MeijiVotes public VOTES;
    ERC20 public gohm;

    constructor(Kernel kernel_, ERC20 gohm_) Policy(kernel_) {
        gohm = gohm_;
    }

    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("INSTR");
        dependencies[1] = toKeycode("VOTES");

        INSTR = MeijiInstructions(getModuleAddress(dependencies[0]));
        VOTES = MeijiVotes(getModuleAddress(dependencies[1]));
    }

    function requestPermissions()
        external
        view
        override
        onlyKernel
        returns (Permissions[] memory requests)
    {
        requests = new Permissions[](2);
        requests[0] = Permissions(INSTR.KEYCODE(), INSTR.store.selector);
        //requests[1] = Permissions(VOTES.KEYCODE(), VOTES.resetActionTimestamp.selector);
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Variables                                //
    /////////////////////////////////////////////////////////////////////////////////


    event ProposalSubmitted(uint256 proposalId, string title, string proposalURI);
    event ProposalRegistered(uint256 proposalId, address voter, uint256 amount);
    event ProposalActivated(uint256 proposalId, uint256 timestamp);
    event VotesCast(uint256 proposalId, address voter, bool approve, uint256 userVotes);
    event ProposalExecuted(uint256 proposalId);
    event CollateralReclaimed(uint256 proposalId, uint256 tokensReclaimed_);


    /// @notice Return a proposal metadata object for a given proposal id.
    mapping(uint256 => ProposalMetadata) public getProposalMetadata;

    /// @notice The amount of gOhm a proposer needs to post in collateral in order to submit a proposal
    /// @dev    This number is expressed as a percentage of total supply in basis points: 500 = 5% of the supply
    uint256 public constant COLLATERAL_REQUIREMENT = 500;

    /// @notice The minimum amount of gOHM the proposer must post in collateral to submit
    uint256 public constant COLLATERAL_MINIMUM = 10e9;

    /// @notice Amount of time a wallet must wait after depositing before they can vote.
    uint256 public constant WARMUP_PERIOD = 1 minutes; // 30 minutes;

    /// @notice Amount of time a submitted proposal must exist before triggering activation.
    uint256 public constant ACTIVATION_TIMELOCK = 1 minutes; // 2 days;

    /// @notice Amount of time a submitted proposal must exist before triggering activation.
    uint256 public constant ACTIVATION_DEADLINE = 2 minutes; // 3 days;

    /// @notice Net votes required to execute a proposal on chain as a percentage of total registered votes.
    uint256 public constant EXECUTION_THRESHOLD = 33;

    /// @notice The period of time a proposal has for voting
    uint256 public constant VOTING_PERIOD = 3 minutes ;  //3 days;

    /// @notice Required time for a proposal to be voting before it can be activated.
    /// @dev    This amount should be greater than 0 to prevent flash loan attacks.
    uint256 public constant EXECUTION_TIMELOCK = 1 minutes;  //2 days;

    /// @notice Amount of time after the proposal is activated (NOT AFTER PASSED) when it can be activated (otherwise proposal will go stale).
    /// @dev    This is inclusive of the voting period (so the deadline is really ~4 days, assuming a 3 day voting window).
    uint256 public constant EXECUTION_DEADLINE = 2 weeks;


    /// @notice Amount of time a non-executed proposal must wait for the proposal to go through.
    /// @dev    This is inclusive of the voting period (so the deadline is really ~4 days, assuming a 3 day voting window).
    uint256 public constant COLLATERAL_DURATION = 16 weeks;


    /////////////////////////////////////////////////////////////////////////////////
    //                               User Actions                                  //
    /////////////////////////////////////////////////////////////////////////////////


    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function submitProposal(
        Instruction[] calldata instructions_,
        string calldata title_,
        string calldata proposalURI_
    ) external {
        // transfer 5% of the total vote supply in gohm (min 10 gOHM)
        uint256 collateral = _min(VOTES.totalSupply() * COLLATERAL_REQUIREMENT / 10000, COLLATERAL_MINIMUM);
        gohm.transferFrom(msg.sender, address(this), collateral);

        uint256 proposalId = INSTR.store(instructions_);
        ProposalMetadata storage proposal = getProposalMetadata[proposalId];

        proposal.submitter = msg.sender;
        proposal.collateralAmt = collateral;
        proposal.submissionTimestamp = block.timestamp;

        //VOTES.resetActionTimestamp(msg.sender);

        emit ProposalSubmitted(proposalId, title_, proposalURI_);
    }

    function activateProposal(uint256 proposalId_) external {
        ProposalMetadata storage proposal = getProposalMetadata[proposalId_];

        if (msg.sender != proposal.submitter) {
            revert NotAuthorized();
        }

        if (block.timestamp < proposal.submissionTimestamp + ACTIVATION_TIMELOCK || 
            block.timestamp > proposal.submissionTimestamp + ACTIVATION_DEADLINE) {
            revert UnableToActivate();
        }

        if (proposal.activationTimestamp != 0) {
            revert ProposalAlreadyActivated();
        }

        proposal.activationTimestamp = block.timestamp;
        proposal.totalRegisteredVotes = VOTES.totalSupply();

        //VOTES.resetActionTimestamp(msg.sender);

        emit ProposalActivated(proposalId_, block.timestamp);
    }


    function vote(uint256 proposalId_, bool approve_) external {
        ProposalMetadata storage proposal = getProposalMetadata[proposalId_];
        uint256 userVotes = VOTES.balanceOf(msg.sender);

        if (proposal.activationTimestamp == 0) {
            revert ProposalIsNotActive();
        }

        /*
        if (VOTES.lastDepositTimestamp(msg.sender) + WARMUP_PERIOD < block.timestamp) {
            revert WarmupNotCompleted();
        }

        if (VOTES.lastDepositTimestamp(msg.sender) > proposal.activationTimestamp) { 
            revert DepositedAfterActivation();
        } */

        if (proposal.votesCastByUser[msg.sender] > 0) {
            revert UserAlreadyVoted();
        }

        if (block.timestamp > proposal.activationTimestamp + VOTING_PERIOD) {
            revert PastVotingPeriod();
        }

        if (approve_) {
            proposal.yesVotes += userVotes;
        } else {
            proposal.noVotes += userVotes;
        }

        proposal.votesCastByUser[msg.sender] = userVotes;
        //VOTES.resetActionTimestamp(msg.sender);

        emit VotesCast(proposalId_, msg.sender, approve_, userVotes);
    }

    function executeProposal(uint256 proposalId_) external {
        ProposalMetadata storage proposal = getProposalMetadata[proposalId_];

        if (msg.sender != proposal.submitter) { 
            revert ExecutorNotSubmitter(); 
        }

        if ((proposal.yesVotes - proposal.noVotes) * 100 < proposal.totalRegisteredVotes * EXECUTION_THRESHOLD) {
            revert NotEnoughVotesToExecute();
        }

        if (proposal.isExecuted) {
            revert ProposalAlreadyExecuted();
        }

        /// @dev    2 days after the voting period ends
        if (block.timestamp < proposal.activationTimestamp + VOTING_PERIOD + EXECUTION_TIMELOCK) {
            revert ExecutionTimelockStillActive();
        }

        /// @dev    7 days after the proposal is SUBMITTED
        if (block.timestamp > proposal.activationTimestamp + EXECUTION_DEADLINE) {
            revert ExecutionWindowExpired();
        }

        Instruction[] memory instructions = INSTR.getInstructions(proposalId_);

        for (uint256 step; step < instructions.length; ) {
            kernel.executeAction(instructions[step].action, instructions[step].target);
            unchecked {
                ++step;
            }
        }

        proposal.isExecuted = true;

        emit ProposalExecuted(proposalId_);
    }

    function reclaimCollateral(uint256 proposalId_) external {
        ProposalMetadata storage proposal = getProposalMetadata[proposalId_];

        if (!proposal.isExecuted && block.timestamp < proposal.activationTimestamp + COLLATERAL_DURATION ) { 
            revert UnmetCollateralDuration();
        }

        if (proposal.isCollateralReturned) {
            revert CollateralAlreadyReturned();
        }

        if (msg.sender != proposal.submitter) {
            revert NotAuthorized();
        }

        proposal.isCollateralReturned = true;
        gohm.transfer(proposal.submitter, proposal.collateralAmt);

        emit CollateralReclaimed(proposalId_, proposal.collateralAmt);
    }
}