// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IFire.sol";

contract FIRE is IFire, ERC20, AccessControl {
    using SafeMath for uint256;
    string internal constant name = "Fire Network";
    string internal constant symbol = "FIRE";

    // Addresses of external contracts
    address external constant UNISWAP_ADDRESS=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Addresses of deployed contracts for calling init
    address internal constant TOKEN_ADDRESS=0x77C81BF05AE3E07c20272E550f650e7f796dD1Ca;
    address internal constant AUCTION_ADDRESS=0x3C55Fa6AAC6Cb044f64ac5AD7527Dc1dA9708177;
    address internal constant STAKING_ADDRESS=0x47009fdb86cE632aafb50B1aC6DFf88c6a439540;
    address internal constant FOREIGN_SWAP_ADDRESS=0xd1043A07F6d5d970b89449F4E9806d57043fEA7b;
    address internal constant BPD_ADDRESS=0x078E7Bfce8f485E37f174D6a453ae1cA4D493147;
    address internal constant SUBBALANCES_ADDRESS=0x81ADe69F59181AF901F920E6ad45696B9748Eff5;

    address internal constant SWAPPER_ADDRESS=0x36C0f2e421bF40Ec28845e81CD4038C19e09E33C;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    IERC20 private swapToken;
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

    constructor(
        string memory _name,
        string memory _symbol,
        address _swapToken,
        address _swapper,
        address _setter
    ) public ERC20(_name, _symbol) {
        _setupRole(SWAPPER_ROLE, _swapper);
        _setupRole(SETTER_ROLE, _setter);
        swapToken = IERC20(_swapToken);
        swapIsOver = false;
    }

    function init(address[] calldata instances) external onlySetter {
        require(instances.length == 5, "NativeSwap: wrong instances number");

        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
        renounceRole(SETTER_ROLE, _msgSender());
        swapIsOver = true;
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

    function getSwapTOken() external view returns (IERC20) {
        return swapToken;
    }

    function getSwapTokenBalance(uint256) external view returns (uint256) {
        return swapTokenBalance;
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

    function initSwap() external onlySwapper {
        require(!swapIsOver, "swap is over");
        uint256 balance = swapTokenBalance;
        swapTokenBalance = 0;
        require(balance > 0, "balance <= 0");
        _mint(_msgSender(), balance);
    }

    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyMinter {
        _burn(from, amount);
    }

    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }
}
