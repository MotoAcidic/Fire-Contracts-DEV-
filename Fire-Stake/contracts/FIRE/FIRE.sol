pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactigions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    string public constant name = "Fire Network";
    string public constant symbol = "FIRE";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 21000000e18;
    uint256 internal constant LAUNCH_TIME = 1575331200;  /* Time of contract launch (2019-12-03T00:00:00Z) */
    
    // 5.25 million coins for swap of old chains
    uint256 contractPremine_ = 5000000e18; // 5m coins
    uint256 devPayment_ = 250000e18; // 250k coins
    uint256 teamPremine_ = 500000e18; // 500k coins
    uint256 abetPremine_ = 2250000e18; // 2.25m coin
    uint256 becnPremine_ = 1750000e18; // 1.75m coin
    uint256 xapPremine_ = 500000e18; // 500k coin
    uint256 xxxPremine_ = 250000e18; // 250k coin
    uint256 beezPremine_ = 250000e18; // 250k coin
    address public _owner;
    address[] internal stakeholders;
    address public contractOwner = msg.sender;
    address public teamAddrs = TEAM_ADDRS;
    address public devAddrs = DEV_ADDRS;
    address public abetAddrs = ABET_ADDRS;
    address public becnAddrs = BECN_ADDRS;
    address public xapAddrs = XAP_ADDRS;
    address public xxxAddrs = XXX_ADDRS;
    address public beezAddrs = BEEZ_ADDRS;
    address internal constant DEV_ADDRS = 0xD53C2fdaaE4B520f41828906d8737ED42b0966Ba;
    address internal constant TEAM_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant ABET_ADDRS = 0x0C8a92f170BaF855d3965BA8554771f673Ed69a6;
    address internal constant BECN_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XAP_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XXX_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant BEEZ_ADDRS = 0x96C418fFc085107aE72127FE70574754ae3D7047;
    
    uint256 private constant WEEKS = 50;
    uint256 internal constant DAYS = WEEKS * 7;
    uint256 private constant START_DAY = 1;
    uint256 internal constant BIG_PAY_DAY = WEEKS + 1;
    uint blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time

    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() public {
    /*mint(DEV_ADDRS, devPayment_);
    mint(msg.sender, contractPremine_);
    mint(TEAM_ADDRS, teamPremine_);
    mint(ABET_ADDRS, abetPremine_);
    mint(BECN_ADDRS, becnPremine_);
    mint(XAP_ADDRS, xapPremine_);
    mint(XXX_ADDRS, xxxPremine_);
    mint(BEEZ_ADDRS, beezPremine_);*/
    emit Transfer(address(0), DEV_ADDRS, devPayment_);
    emit Transfer(address(0), msg.sender, contractPremine_);
    emit Transfer(address(0), TEAM_ADDRS, teamPremine_);
    emit Transfer(address(0), ABET_ADDRS, abetPremine_);
    emit Transfer(address(0), BECN_ADDRS, becnPremine_);
    emit Transfer(address(0), XAP_ADDRS, xapPremine_);
    emit Transfer(address(0), XXX_ADDRS, xxxPremine_);
    emit Transfer(address(0), BEEZ_ADDRS, beezPremine_);
    }

    // ------------------------------------------------------------------------
    //                              Premine Functions
    // ------------------------------------------------------------------------

    function contractPremine() public view returns (uint256) { return contractPremine_; }
    function teamPremine() public view returns (uint256) { return teamPremine_; }
    function devPayment() public view returns (uint256) { return devPayment_; }
    function abetPremine() public view returns (uint256) { return abetPremine_; }
    function becnPremine() public view returns (uint256) { return becnPremine_; }
    function xapPremine() public view returns (uint256) { return xapPremine_; }
    function xxxPremine() public view returns (uint256) { return xxxPremine_; }
    function beezPremine() public view returns (uint256) { return beezPremine_; }
    
    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return _balances[tokenOwner];
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) public override returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= _balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        _balances[owner] = _balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns(bool success) {
        require(_balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        _balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public
    {
        
        emit Burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public
    {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        mint(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) 
        public
        view
        returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder] / 100;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards() 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() 
        public
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        mint(msg.sender, reward);
    }
    
}


abstract contract DEX {
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IERC20 public token;


    
    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }
    
    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }

}