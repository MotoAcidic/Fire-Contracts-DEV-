pragma solidity ^0.6.0;
    
import "./interfaces/IFIRE.sol";    
import "./libraries/EnumerableSet.sol";
import "./libraries/SafeMath.sol";
import "./FIRE.sol";

contract swap {
    using SafeMath for uint256;
    // ------------------------------------------------------------------------
    //                              Role Based Setup
    // ------------------------------------------------------------------------
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ABET_SWAP_ROLE = keccak256("ABET_SWAP_ROLE");
    
    function grantMinerRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant minter role.");
        grantRole(MINTER_ROLE, account);
    }
    
    function grantBurnerRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant burner role.");
        grantRole(BURNER_ROLE, account);
    }
    
    function grantSwapRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant swap role.");
        grantRole(SWAP_ROLE, account);
    }

    function sendAbet(address receiver, uint amount) public {
        require(hasRole(SWAP_ROLE, msg.sender), "Need to be a swapper");
        address swapAddress = ABET_ADDRS;
        
        _balances[swapAddress] = SafeMath.sub(_balances[swapAddress], amount);
        _balances[receiver] = SafeMath.add(_balances[receiver], amount);
        emit Transfer(swapAddress, receiver, amount);
    }
}