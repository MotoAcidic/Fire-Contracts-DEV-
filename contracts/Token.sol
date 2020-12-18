pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../Interfaces/IToken.sol";

contract Token is ERC20("Fire Network", "Fire"), Ownable, AccessControl{
  using SafeMath for uint256;

  uint public _totalSupply = 750000000000e18; //750b
        // Premine values
  uint256 premineTotal = 676000000000e18; // 675b coins total on launch
  uint256 presalePremine = 250000000000e18; // 250b coins
  uint256 devPayment = 1000000000e18; // 1b coins
  uint256 swapPremine = 250000000000e18; // 250b coins
  uint256 uinswapPremine = 75000000000e18; // 75b coins
  uint256 devFundPremine = 75000000000e18; // 75b coins
  uint256 teamPremine = 25000000000e18; // 25b coins

  event Burn(address indexed from, uint256 value);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Mint(address indexed _address, uint _reward);

  mapping(address => uint256) private balances;

  address internal constant _presaleAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _devAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _swapAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _uinswapAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _devFundAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _teamAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
    _;
  }

  modifier onlySetter() {
      require(hasRole(SETTER_ROLE, _msgSender()), "Caller is not a setter");
      _;
  }
  
  constructor() public {
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(SETTER_ROLE, msg.sender);
    
    _mint(msg.sender, premineTotal);
    _mint(_devAddress, devPayment);
  }

    // ------------------------------------------------------------------------
    //                              Role Based Setup
    // ------------------------------------------------------------------------
    
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");
    
    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

  function _balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  function mint(address to, uint256 amount) external onlyMinter {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter {
      _burn(from, amount);
  }
    
}

