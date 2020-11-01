pragma solidity 0.6.0;

interface IERC20 {

    //function totalSupply() external view returns (uint256);
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

    string public constant name = "Fire Network";
    string public constant symbol = "FIRE";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 21000000; //21m coins
    address public contractOwner = msg.sender;
    
    // 5 million coins for swap of old chains
    uint256 contractPremine_ = 5000000; // 5m coins
    uint256 devPayment_ = 250000; // 250k coins
    uint256 teamPremine_ = 500000; // 500k coins
    uint256 abetPremine_ = 2250000; // 2.25m coin
    uint256 becnPremine_ = 1750000; // 1.75m coin
    uint256 xapPremine_ = 500000; // 500k coin
    uint256 xxxPremine_ = 250000; // 250k coin
    uint256 beezPremine_ = 250000; // 250k coin
    address internal constant DEV_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant TEAM_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant ABET_ADDRS = 0x0C8a92f170BaF855d3965BA8554771f673Ed69a6;
    address internal constant BECN_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XAP_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant XXX_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    address internal constant BEEZ_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    
    uint blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time
    uint public rewardPerDay = 50; // Amount perday you can claim from the dividend
    uint public minNodeStakeAmount = 5000; // Min amount to needed to node stake
    uint256 public scaledRewardPerToken = blocksAday / rewardPerDay; // Calc for the reward to equal only 50 coins paid out perday
    

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

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
    
    // ------------------------------------------------------------------------
    // Balance of token holder
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Change Required Tokens for payouts
    // ------------------------------------------------------------------------
    function changeRequiredTokens(uint _value) public override {
        minNodeStakeAmount = _value;
    }
    
    // ------------------------------------------------------------------------
    // Change reward amount payout amount
    // ------------------------------------------------------------------------
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
        totalSupply -= _value;                      // Updates totalSupply
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
        totalSupply -= _value;                              // Update totalSupply
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