// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
import "./interfaces/IToken.sol";

contract Token is IToken, Context, AccessControl {
    using SafeMath for uint256;
    
    string public constant name = "FIRE Network";
    string public constant symbol = "FIRE";
    uint8 internal constant decimals = 18;
    
    uint256 public constant LIMIT = 250000000000e18;
    uint256 public constant RATE = 1e6;
    
    uint256  _totalSupply = 21000000e18; //21m
    uint256 premineTotal_ = 10250000e18; // 10.25m coins total on launch
    uint256  _circulatingSupply = 0; //Set to 0 at start
    
    address internal contractOwner = msg.sender;
    address SWAPPER_ADDRESS = 0x36C0f2e421bF40Ec28845e81CD4038C19e09E33C;
    address TOKEN_ADDRESS = 0x77C81BF05AE3E07c20272E550f650e7f796dD1Ca;
    address AUCTION_ADDRESS = 0x3C55Fa6AAC6Cb044f64ac5AD7527Dc1dA9708177;
    address STAKING_ADDRESS = 0x47009fdb86cE632aafb50B1aC6DFf88c6a439540;
    address FOREIGN_SWAP_ADDRESS = 0xd1043A07F6d5d970b89449F4E9806d57043fEA7b;
    address BPD_ADDRESS = 0x078E7Bfce8f485E37f174D6a453ae1cA4D493147;
    address SUBBALANCES_ADDRESS = 0x81ADe69F59181AF901F920E6ad45696B9748Eff5;
    address SIGNER_ADDRESS = 0x849d89FfA8F91fF433A3A1D23865d15C8495Cc7B;
    address _owner;
    
    // Auction init parameters
    address MANAGER_ADDRESS = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    address ETH_RECIPIENT = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    
    // HEX Params
    uint256 private constant AUTOSTAKE_PERIOD = 350;
    uint256 private constant MAX_CLAIM_AMOUNT = 10000000000000000000000000;
    uint256 private constant TOTAL_SNAPSHOT_AMOUNT = 370121420541683530700000000000;
    uint256 private constant TOTAL_SNAPSHOT_ADDRESSES = 183035;
    
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Sent(address from, address to, uint amount);
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    bool private swapIsOver;
    uint256 private swapTokenBalance;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _;
    }

    modifier onlySetter() {
        require(hasRole(SETTER_ROLE, _msgSender()), "Caller is not a setter");
        _;
    }

    modifier onlySwapper() {
        require(hasRole(SWAPPER_ROLE, _msgSender()), "Caller is not a swapper");
        _;
    }

    constructor() public
    {
        _setupRole(SWAPPER_ROLE, msg.sender);
        _setupRole(SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _circulatingSupply = _circulatingSupply.add(premineTotal_);
        swapIsOver = false;
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() public override view returns (uint256) {
        return _circulatingSupply;
    }

    function init(address[] calldata instances) external onlySetter {
        require(instances.length == 5, "NativeSwap: wrong instances number");

        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
        renounceRole(SETTER_ROLE, _msgSender());
        swapIsOver = true;
    }
    
    function mint(address to, uint256 amount) external override onlyMinter {
        _circulatingSupply = _circulatingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        mint(account, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        transfer(sender, recipient, amount);
        approve(sender, msg.sender(), allowance[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        approve(_msgSender(), spender, allowance[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSwapperRole() external pure returns (bytes32) {
        return SWAPPER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }



    function initDeposit(uint256 _amount) external onlySwapper {
        require(
            swapToken.transferFrom(_msgSender(), address(this), _amount),
            "Token: transferFrom error"
        );
        swapTokenBalance = swapTokenBalance.add(_amount);
    }

    function initWithdraw(uint256 _amount) external onlySwapper {
        require(_amount <= swapTokenBalance, "amount > balance");
        swapTokenBalance = swapTokenBalance.sub(_amount);
        swapToken.transfer(_msgSender(), _amount);
    }





    function burn(address from, uint256 amount) external override onlyMinter {
        Burn(from, amount);
    }

    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }
}
