pragma solidity ^0.8.14;

interface LiquidityGauge {
    function integrate_faction(address addr) external view returns (uint256);
    function user_checkpoint(address addr) external returns (bool);
}

interface MERC20 {
    function mint(address _to, uint256 _value) external returns (bool);
}

interface GaugeController {
    function gauge_types(address addr) external view returns (int128);
}

contract Minter {
    address private immutable token;
    address private immutable controller;

    // Maybe make a double key mapping?
    mapping(address => mapping(address => uint256)) public minted;
    mapping(address => mapping(address => bool)) public allowed_to_mint_for;
    
    constructor(address _token, address _controller) external {
        token = _token;
        constructor = _contructor;
    }

    modifier lock() {
        require(locked == 1);

        locked = 2;

        _;

        locked = 1;
    }

    function _mint_for(address gauge_address, address _for) internal {
        require(GaugeController(controller).gauge_types(gauge_address) >= 0); # dev: Gauge is not allowed

        LiquidityGauge(gauge_address).user_checkpoint(_for);
    
        uint256 total_mint = LiquidityGauge(gauge_address).integrate_fraction(_for);
        uint256 to_mint = total_mint - minted[_for][_gauge_address];

        if (to_mint != 0) {
            MERC20(token).mint(_for, to_mint);
            minted[_for][gauge_address] = total_mint;

            emit Minted(_for, gauge_address, total_mint);
        }
    }

    function mint(address gauge_address) external lock {
        _mint_for(gauge_address, msg.sender);
    }

    function mint_many(address[8[ calldata gauge_addresses) external lock {
        for(uint256 i = 0; i < 8; ++i) {
            if(gauge_addresses[i] == address(0)) {
                break;
            }
            _mint_for(gauge_addresses[i], msg.sender);
        }
    }


    function mint_for(address gauge_address, address _for) external lock {
    
        if (allowed_to_mint_for[msg.sender][_for]) {
            _mint_for(gauge_address, msg.sender);
        }
    }
    
    function toggle_approve_mint(address minting_user) external {
        allowed_to_mint_for[minting_user][msg.sender] = !allowed_to_mint_for[minting_user][msg.sender]
    }
}
