pragma solidity 0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);
    
    function changeRequiredTokens(uint _value) external;
    function changeNodeReward(uint _value) external;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is IERC20 {
    using SafeMath for uint256;
    string public constant name = "Fire Network";
    string public constant symbol = "FIRE";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 21000000; //21m coins
    
    /* Size of a Shares uint */
    uint256 internal constant SHARE_UINT_SIZE = 72;
    uint256 internal constant LAUNCH_TIME = 1575331200;  /* Time of contract launch (2019-12-03T00:00:00Z) */
    
    // 5.25 million coins for swap of old chains
    uint256 contractPremine_ = 5000000; // 5m coins
    uint256 devPayment_ = 250000; // 250k coins
    uint256 teamPremine_ = 500000; // 500k coins
    uint256 abetPremine_ = 2250000; // 2.25m coin
    uint256 becnPremine_ = 1750000; // 1.75m coin
    uint256 xapPremine_ = 500000; // 500k coin
    uint256 xxxPremine_ = 250000; // 250k coin
    uint256 beezPremine_ = 250000; // 250k coin
    address public contractOwner = msg.sender;
    address public teamAddrs = TEAM_ADDRS;
    address public devAddrs = DEV_ADDRS;
    address public abetAddrs = ABET_ADDRS;
    address public becnAddrs = BECN_ADDRS;
    address public xapAddrs = XAP_ADDRS;
    address public xxxAddrs = XXX_ADDRS;
    address public beezAddrs = BEEZ_ADDRS;
    address internal constant DEV_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant TEAM_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant ABET_ADDRS = 0x0C8a92f170BaF855d3965BA8554771f673Ed69a6;
    address internal constant BECN_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XAP_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XXX_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant BEEZ_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    
    uint256 private constant WEEKS = 50;
    uint256 internal constant DAYS = WEEKS * 7;
    uint256 private constant START_DAY = 1;
    uint256 internal constant BIG_PAY_DAY = WEEKS + 1;
    uint blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time
    uint public rewardPerDay = 50; // Amount perday you can claim from the dividend
    uint public minNodeStakeAmount = 5000; // Min amount to needed to node stake
    uint256 public scaledRewardPerToken = blocksAday / rewardPerDay; // Calc for the reward to equal only 50 coins paid out perday

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() public {  
	balances[msg.sender] = contractPremine();
	balances[DEV_ADDRS] = devPayment();
	balances[TEAM_ADDRS] = teamPremine();
	balances[ABET_ADDRS] = abetPremine();
	balances[BECN_ADDRS] = becnPremine();
	balances[XAP_ADDRS] = xapPremine();
	balances[XXX_ADDRS] = xxxPremine();
	balances[BEEZ_ADDRS] = beezPremine();
    } 
    
    /* Percentage of total claimed Hearts that will be auto-staked from a claim */
    uint256 internal constant AUTO_STAKE_CLAIM_PERCENT = 90;

    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MIN_AUTO_STAKE_DAYS = 350;
    uint256 internal constant MAX_STAKE_DAYS = 5555; // Approx 15 years
    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;
    uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7;
    uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7;
    uint256 internal constant SHARE_RATE_SCALE = 1e5; /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40; /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;
    

    
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
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function changeRequiredTokens(uint _value) public override {
        minNodeStakeAmount = _value;
    }

    function changeNodeReward(uint _value) public override {
        rewardPerDay = _value;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
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
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
}
library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract DEX {
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IERC20 public token;

    constructor() public {
        token = new ERC20();
    }
    
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