// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IFIRE.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";





abstract contract DEX {
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    IFIRE public token;
    
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

contract FIRE is Context, IFIRE, AccessControl {
    using SafeMath for uint256;
   
    string internal constant name = "Fire Network";
    string internal constant symbol = "FIRE";
    uint8 internal constant decimals = 18;
    uint256  _totalSupply = 21000000e18; //21m
    uint256  _circulatingSupply = 0; //Set to 0 at start

    address _owner;
    address internal contractOwner = msg.sender;
    
    uint256 premineTotal_ = 10250000e18; // 10.25m coins total on launch
    uint256 contractPremine_ = 5000000e18; // 5m coins
    uint256 devPayment_ = 250000e18; // 250k coins
    uint256 teamPremine_ = 500000e18; // 500k coins
    
    address teamAddrs = TEAM_ADDRS;
    address devAddrs = DEV_ADDRS;
    address internal constant DEV_ADDRS = 0xD53C2fdaaE4B520f41828906d8737ED42b0966Ba;
    address internal constant TEAM_ADDRS = 0xe3C17f1a7f2414FF09b6a569CdB1A696C2EB9929;
    
    // Time based variables
    uint256 unlockTime;
    uint256 private constant WEEKS = 50;
    uint256 internal constant DAYS = WEEKS * 7;
    uint256 private constant START_DAY = 1;
    uint256 internal constant days_year = 365;
    uint256 internal constant secondsAday = 86400;
    uint256 internal constant blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time
    
    uint256 internal constant _interestBaseRate = 600; //6%
    

    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Sent(address from, address to, uint amount);
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => stakeData) stakeParams; 
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    
    address[] internal stakeholders;
    
    struct stakeData { 
        address account;
        uint256 amount; 
        uint256 start; 
        uint256 end;
        uint256 interest;
    }
    
    //StakeData[] StakeParams;
    
    
    constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    
    mint(DEV_ADDRS, devPayment_);
    mint(msg.sender, contractPremine_);
    mint(TEAM_ADDRS, teamPremine_);

    _circulatingSupply = _circulatingSupply.add(premineTotal_);
    emit Transfer(address(0), DEV_ADDRS, devPayment_);
    emit Transfer(address(0), msg.sender, contractPremine_);
    emit Transfer(address(0), TEAM_ADDRS, teamPremine_);
    }
    
    // ------------------------------------------------------------------------
    //                              Role Based Setup
    // ------------------------------------------------------------------------
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    
    function grantMinerRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant minter role.");
        grantRole(MINTER_ROLE, account);
    }
    function grantBurnerRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant burner role.");
        grantRole(BURNER_ROLE, account);
    }

    // ------------------------------------------------------------------------
    //                              Premine Functions
    // ------------------------------------------------------------------------

    function mint(address account, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _circulatingSupply = _circulatingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() public override view returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return _balances[tokenOwner];
    }
    
    function send(address receiver, uint amount) public {
        require(amount <= _balances[msg.sender], "Insufficient balance.");
        _balances[msg.sender] -= amount;
        _balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
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
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns(bool success) {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
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
    function createStake(uint256 _stake, uint stakingDays) public {
        require(stakingDays > 0, "stakingDays < 1");
        emit Burn(msg.sender, _stake);

        // Set the time it takes to unstake
        unlockTime = now.add(stakingDays.mul(secondsAday));
        
        uint256 stakingInterest;
        uint256 stakingInterestCalc;
        uint256 stakingDaysCalc;
        stakingDaysCalc = roundedDiv(days_year, stakingDays);
        //stakingInterestCalc = bankersRoundedDiv(_interestBaseRate, 100);
        
        //stakingInterest = _stake.mul(1 + (stakingInterestCalc.mul(_interestBaseRate)));
        stakingInterestCalc = _stake.mul(_interestBaseRate).div(10000);
        stakingInterest = bankersRoundedDiv(stakingInterestCalc, stakingDaysCalc);

        stakeData memory stakeData_ = stakeData({
            account: msg.sender,
            amount: _stake,
            start: now,
            end: unlockTime,
            interest: stakingInterest
        });
        
        stakeParams[msg.sender] = stakeData_;
        
        //Add the staker to the stake array
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }
    
    function aaTestStake (uint256 _stake, uint stakingDays) public {

        // Set the time it takes to unstake
        unlockTime = now.add(stakingDays.mul(secondsAday));
        
        uint256 stakingInterest;
        uint256 stakingInterestCalc;
        uint256 stakingDaysCalc;
        stakingDaysCalc = roundedDiv(days_year, stakingDays);
        //stakingInterestCalc = bankersRoundedDiv(_interestBaseRate, 100);
        
        //stakingInterest = _stake.mul(1 + (stakingInterestCalc.mul(_interestBaseRate)));
        stakingInterestCalc = _stake.mul(_interestBaseRate).div(10000);
        stakingInterest = bankersRoundedDiv(stakingInterestCalc, stakingDaysCalc);
        
        // Save the staking params to the struct
       stakeData memory stakeData_ = stakeData({
            account: msg.sender,
            amount: _stake,
            start: now,
            end: unlockTime,
            interest: stakingInterest
        });
        
        stakeParams[msg.sender] = stakeData_;
 
    }
   
    
    function returnStakerInfo(address stakerAccount) public view returns (address account, uint256 amount, uint256 start, uint256 end, uint256 interest){
            return (stakeParams[stakerAccount].account,
                    stakeParams[stakerAccount].amount,
                    stakeParams[stakerAccount].start,
                    stakeParams[stakerAccount].end,
                    stakeParams[stakerAccount].interest);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake) public {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        uint256 claimedAmount = claimableAmount(msg.sender);
        mint(msg.sender, claimedAmount);
    }


    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns(uint256) {
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
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    function claimableAmount(address account) public view returns (uint256){
        
        uint256 stakingDays = (stakeParams[account].end.sub(stakeParams[account].start)).div(blocksAday);
        uint256 daysStaked = (now.sub(stakeParams[msg.sender].start)).div(blocksAday);
        uint256 amountAndInterest = stakeParams[msg.sender].amount.add(stakeParams[msg.sender].interest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount = amountAndInterest.mul(daysStaked).div(stakingDays);
            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);
            uint256 amountClaimed = payOutAmount.sub(earlyUnstakePenalty);

            return amountClaimed;
            // In time
        } else if (stakingDays <= daysStaked && daysStaked < stakingDays.add(14)) {
            return amountAndInterest;
            
            // Late
        } else if (stakingDays.add(14) <= daysStaked && daysStaked < stakingDays.add(714)) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);
            uint256 payOutAmount = amountAndInterest.mul(uint256(714).sub(daysAfterStaking)).div(700);
            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);
            uint256 amountClaimed = payOutAmount.sub(lateUnstakePenalty);

            return amountClaimed;
            // Nothing
        } else if (stakingDays.add(714) <= daysStaked) {
            return amountAndInterest;
        }

        return 0;
        
    }
     
    function rewardOf(address _stakeholder) public view returns(uint256) {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256) {
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
    function calculateReward(address _stakeholder) public view returns(uint256) {
        return stakes[_stakeholder] / 100;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not the admin");
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        mint(msg.sender, reward);
    }
    
        /**
     * @dev bankersRoundedDiv method that is used to divide and round the result 
     * (AKA round-half-to-even)
     *
     * Bankers Rounding is an algorithm for rounding quantities to integers, 
     * in which numbers which are equidistant from 
     * the two nearest integers are rounded to the nearest even integer. 
     *
     * Thus, 0.5 rounds down to 0; 1.5 rounds up to 2. 
     * Other decimal fractions round as you would expect--0.4 to 0, 0.6 to 1, 1.4 to 1, 1.6 to 2, etc. 
     * Only x.5 numbers get the "special" treatment.
     * @param a What to divide
     * @param b Divide by this number
     */
    function bankersRoundedDiv(uint256 a, uint256 b) public pure returns (uint256) {
        require(b > 0, "div by 0"); 

        uint256 halfB = 0;
        if ((b % 2) == 1) {
            halfB = (b / 2) + 1;
        } else {
            halfB = b / 2;
        }
        bool roundUp = ((a % b) >= halfB);

        // now check if we are in the center!
        bool isCenter = ((a % b) == (b / 2));
        bool isDownEven = (((a / b) % 2) == 0);

        // select the rounding type
        if (isCenter) {
            // only in this case we rounding either DOWN or UP 
            // depending on what number is even 
            roundUp = !isDownEven;
        }

        // round
        if (roundUp) {
            return ((a / b) + 1);
        }else{
            return (a / b);
        }
    }
    
     /**
     * @dev Division, round to nearest integer (AKA round-half-up)
     * @param a What to divide
     * @param b Divide by this number
     */
    function roundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity automatically throws, but please emit reason
        require(b > 0, "div by 0"); 

        uint256 halfB = (b % 2 == 0) ? (b / 2) : (b / 2 + 1);
        return (a % b >= halfB) ? (a / b + 1) : (a / b);
    }
    
}


