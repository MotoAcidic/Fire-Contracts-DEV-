// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IFIRE.sol";
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
    uint256 internal _totalSupply = 0;
    uint256 public maxSupply = 21000000e18; //21m
    uint256 internal _stakingSupply = 0;
    uint256 internal _bigPayoutThreshold = 100000000; // 1m coins from early end stakes
    uint256 public bigPayoutPool = 500;
    uint256 internal _unStakeGracePeriod = 14; // Amount in days
    uint256 internal _maxUnstakePeriod = 365; // Amount in days

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
    
    
    uint256 internal constant _burnPercent = 2; // .02% in basis points
    uint256 private _sessionsIds;

   /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event stake(address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end);
    event FrozenFunds(address target, bool frozen);
    event Mint(address indexed _address, uint _reward);
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    
    mapping(address => stakeData) stakeParams;
    mapping(uint256 => stakeData) sessionStakeData;
    
    mapping (address => bool) public frozenAccount;
    
    
    address[] internal stakeholders;
    
    struct stakeData { 
        address account;
        uint256 amount; 
        uint256 start; 
        uint256 end;
        uint256 interest;
        uint256 stakeDays;
        uint256 session;
    }
    
    struct Session { 
        uint256 amount; 
        uint256 start; 
        uint256 end;
        
    }
    
    constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(SETTER_ROLE, msg.sender);
    _setupRole(MR_FREEZE_ROLE, msg.sender);
    
    mint(DEV_ADDRS, devPayment_);
    mint(msg.sender, contractPremine_);
    mint(TEAM_ADDRS, teamPremine_);

    _totalSupply = _totalSupply.add(premineTotal_);
    emit Transfer(address(0), DEV_ADDRS, devPayment_);
    emit Transfer(address(0), msg.sender, contractPremine_);
    emit Transfer(address(0), TEAM_ADDRS, teamPremine_);
    }
    
    modifier canPoSMint() {
        require(_totalSupply < maxSupply);
        _;
    }
    
    // ------------------------------------------------------------------------
    //                              Role Based Setup
    // ------------------------------------------------------------------------
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant MR_FREEZE_ROLE = keccak256("MR_FREEZE_ROLE");
    
    function grantMinerRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant minter role.");
        grantRole(MINTER_ROLE, account);
    }
    
    function grantMrFreezeRole(address account) public{
        require(hasRole(MR_FREEZE_ROLE, msg.sender), "Mr. Freeze can only grant his freeze abiltity to others..");
        grantRole(MR_FREEZE_ROLE, account);
    }
    
    function grantSetterRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant minter role.");
        grantRole(MINTER_ROLE, account);
    }
    
    function freezeAccount(address target, bool freeze) public {
        require(hasRole(MR_FREEZE_ROLE, msg.sender), "Only Mr. Freeze can freeze people silly.");
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function mint(address account, uint256 amount) public {
        require(!frozenAccount[msg.sender]);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    /*
    function mintReward(uint256 amount) public canPoSMint returns (bool) {
        require(!frozenAccount[msg.sender]);
        //uint256 senderID = stakeParams[msg.sender].session;
        
        //uint reward = claimableAmount(senderID);
        //if(msg.sender != sessionStakeData[senderID].account) return false;
        
        // Testing reward function Only
        uint256 reward = amount;
        //delete sessionStakeData[senderID].session;
        
        if(reward <= 0) return false;
        
        _totalSupply = _totalSupply.add(reward);
        
        _balances[msg.sender] = _balances[msg.sender].add(reward);

        emit Transfer(address(0), msg.sender, reward);
        return true;
    }
    */
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!frozenAccount[msg.sender]);
        uint256 finalAmount;
        uint256 amountToBurn = amount.mul(_burnPercent).div(10000);
        _beforeTokenTransfer(msg.sender, address(0), amountToBurn);

        _balances[msg.sender] = _balances[msg.sender].sub(amountToBurn, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amountToBurn);
        emit Transfer(msg.sender, address(0), amountToBurn);
        
        finalAmount = amount.sub(amountToBurn);
        

        _beforeTokenTransfer(msg.sender, recipient, finalAmount);

        _balances[msg.sender] = _balances[msg.sender].sub(finalAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(finalAmount);
        emit Transfer(msg.sender, recipient, finalAmount);
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
        require(!frozenAccount[msg.sender]);
        require(numTokens <= _balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        _balances[owner] = _balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function burnFrom(address _from, uint256 _value) public returns(bool success) {
        require(_balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        _balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        burn(msg.sender, _value);
        return true;
    }

    // ---------- STAKES ----------

     
    function createStake(uint256 amount, uint256 stakingDays) public returns (uint256){
        require(_balances[msg.sender] >= amount, "You can only stake what you own.");
        require(stakingDays > 0, "stakingDays < 1");
        
        _beforeTokenTransfer(msg.sender, address(0), amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        
        // Set the time it takes to unstake
        unlockTime = now.add(stakingDays.mul(secondsAday));
        
        uint256 _interestBaseRate;
        uint256 _interestDayRate;
        uint256 _interestRate;
        uint256 sessionId = _sessionsIds;
        uint256 stakingInterest;
        uint256 stakingDaysCalc;
        
        if(stakingDays >= 15 && stakingDays <= 30){
            _interestBaseRate = 500; // 5%
            _interestDayRate = 33; // .33% perday
            stakingDaysCalc = stakingDays.sub(15);
            _interestRate = stakingDaysCalc.mul(_interestDayRate).add(_interestBaseRate);
        }else if(stakingDays > 30 && stakingDays <= 90){
            _interestBaseRate = 1200; // 12%
            _interestDayRate = 40; // .40% perday
            stakingDaysCalc = stakingDays.sub(30);
            _interestRate = stakingDaysCalc.mul(_interestDayRate).add(_interestBaseRate);
        }else if(stakingDays > 90 && stakingDays <= 180){
            _interestBaseRate = 4200; // 42%
            _interestDayRate = 47; // .47% perday
            stakingDaysCalc = stakingDays.sub(90);
            _interestRate = stakingDaysCalc.mul(_interestDayRate).add(_interestBaseRate);
        }else if(stakingDays > 180 && stakingDays <= 360){
            _interestBaseRate = 9600; // 96%
            _interestDayRate = 53; // .53 perday
            stakingDaysCalc = stakingDays.sub(180);
            _interestRate = stakingDaysCalc.mul(_interestDayRate).add(_interestBaseRate);
        }else if(stakingDays > 360){
            _interestBaseRate = 22000; // 220%
            _interestDayRate = 61; // .61%
            stakingDaysCalc = stakingDays.sub(360);
            _interestRate = stakingDaysCalc.mul(_interestDayRate).add(_interestBaseRate);
        }
        //emit Burn(msg.sender, amount);
        
        _sessionsIds = _sessionsIds.add(1);
        stakingInterest = amount.mul(_interestRate).div(10000);

        stakeData memory stakeData_ = stakeData({
            account: msg.sender,
            amount: amount,
            session: sessionId,
            start: now,
            end: unlockTime,
            stakeDays: stakingDays,
            interest: stakingInterest
        });
        
        stakeParams[msg.sender] = stakeData_;
        sessionStakeData[sessionId] = stakeData_;
        
        //Increase staking supply
        _stakingSupply.add(amount);
        
        //If user is not already in the stakes array add them for bpd payouts
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
        
        emit stake(msg.sender, sessionId, amount, now, unlockTime);
        
        return (sessionId);
    }

    function distributeBigPayout() public {
        require(!frozenAccount[msg.sender]);
        require(bigPayoutPool >= _bigPayoutThreshold); //bigPayout must be over 1m coins to payout to holders
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateBPD(stakeholder);
            //rewards[stakeholder] = rewards[stakeholder].add(reward);
            mint(stakeholder, reward);
        }
    }
    
    function calculateBPD(address account) public view returns(uint256) {
        require(bigPayoutPool > 100, "Must be at least 100 tokens in payout pool to calculate");
        uint256 rewardPercentage = roundedDiv(stakes[account], bigPayoutPool).mul(100);
        uint256 reward = rewardPercentage.div(10000).mul(bigPayoutPool);
        
        return reward;
    }
    
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }
   
    function aaTest () public {
        require(!frozenAccount[msg.sender]);
        require(bigPayoutPool >= _bigPayoutThreshold); //bigPayout must be over 1m coins to payout to holders
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateBPD(stakeholder);
            //rewards[stakeholder] = rewards[stakeholder].add(reward);
            mint(stakeholder, reward);
        }
    }
   
     /*
    function returnStakerInfo(address stakerAccount) public view returns (address account, uint256 amount, uint256 session, uint256 start, uint256 end, uint256 interest){
            return (stakeParams[stakerAccount].account,
                    stakeParams[stakerAccount].amount,
                    stakeParams[stakerAccount].session,
                    stakeParams[stakerAccount].start,
                    stakeParams[stakerAccount].end,
                    stakeParams[stakerAccount].interest
                    );
    }
    
    */
    
    function returnSessionInfo(uint256 sessionID) public view returns (address account, uint256 amount, uint256 session, uint256 start, uint256 end, uint256 stakeDays, uint256 interest){
            return (sessionStakeData[sessionID].account,
                    sessionStakeData[sessionID].amount,
                    sessionStakeData[sessionID].session,
                    sessionStakeData[sessionID].start,
                    sessionStakeData[sessionID].end,
                    sessionStakeData[sessionID].stakeDays,
                    sessionStakeData[sessionID].interest
                    );
    }

     /*
    function removeStake(uint256 _stake, uint256 sessionID) public {
        require(!frozenAccount[msg.sender]);
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        uint256 claimedAmount = claimableAmount(sessionID);

        delete sessionStakeData[sessionID];
        _stakingSupply.sub(sessionStakeData[sessionID].amount);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _initPayout(msg.sender, claimedAmount);
        //mint(msg.sender, claimedAmount);
    }
    
    function _initPayout(address to, uint256 amount) internal {
        mint(to, amount);
    }
    */
    
    function removeStake(uint256 sessionID) public returns (bool) {
        require(!frozenAccount[msg.sender], "This account is frozen");
        require(sessionStakeData[sessionID].account == msg.sender, "You can only claim your own stakes");
        uint256 sessionAmount = sessionStakeData[sessionID].amount;
        //uint256 senderID = stakeParams[msg.sender].session;
        
        // Subtract the stake from session stakes so they both match
        stakes[msg.sender] = stakes[msg.sender].sub(sessionAmount);
        
        // Reducing the total stake supply from the stake thats ending
        
        // If this is the last stake the user has then remove them from 
        // the global staker array
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        
        //uint reward = claimableAmount(senderID);
        uint reward = sessionAmount;
        
        _totalSupply = _totalSupply.add(reward);
        
        _balances[msg.sender] = _balances[msg.sender].add(reward);
        
        delete sessionStakeData[sessionID];
        emit Transfer(address(0), msg.sender, reward);
        return true;
    }
    
    function _initPayout(address to, uint256 amount) internal {
        mint(to, amount);
    }
    function claimableAmount(uint256 sessionID) public view returns (uint256){
        require(now.sub(sessionStakeData[sessionID].start) > secondsAday, "You must have been staked for 1 full day first.");
        
        // ------------------------------------------------------------------------
        //                             Time Based Calculations
        // ------------------------------------------------------------------------
        
        uint256 timeStaked = now.sub(sessionStakeData[sessionID].start);
        uint256 stakingDays = sessionStakeData[sessionID].end.sub(sessionStakeData[sessionID].start).div(60).div(60).div(24);
        uint256 daysStaked = now.sub(sessionStakeData[sessionID].start).div(60).div(60).div(24);
        uint256 timeForFullReward = sessionStakeData[sessionID].end.sub(sessionStakeData[sessionID].start);
        
        uint256 amountAndInterest = sessionStakeData[sessionID].amount.add(sessionStakeData[sessionID].interest);
        
        // ------------------------------------------------------------------------
        //                             Claimed to early
        // ------------------------------------------------------------------------
        
        if (stakingDays > daysStaked) {
            uint256 payOutAmount = amountAndInterest.mul(daysStaked).div(stakingDays);
            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);
            uint256 amountClaimed = payOutAmount.sub(earlyUnstakePenalty);
            uint256 endEarlyStaked = amountAndInterest.sub(amountClaimed);
            bigPayoutPool.add(endEarlyStaked);
            return amountClaimed;
            
        // ------------------------------------------------------------------------
        //              Claimed on time and under endStake grace period
        // ------------------------------------------------------------------------
        
        } else if (timeForFullReward <= timeStaked && timeStaked < timeStaked.add(secondsAday.mul(_unStakeGracePeriod))) {
            
            return amountAndInterest;
            
        // ------------------------------------------------------------------------
        //             Claimed after endStake grace period with penalties
        // ------------------------------------------------------------------------
        
        } else if (stakingDays.add(_unStakeGracePeriod) <= daysStaked && daysStaked < stakingDays.add(_maxUnstakePeriod)) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);
            uint256 payOutAmount = amountAndInterest.mul(uint256(_maxUnstakePeriod).sub(daysAfterStaking)).div(700);
            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);
            uint256 amountClaimed = payOutAmount.sub(lateUnstakePenalty);

            return amountClaimed;
            
        // ------------------------------------------------------------------------
        //             Claimed to late all funds are moved to BPD pool
        // ------------------------------------------------------------------------
        
        } else if (stakingDays.add(_maxUnstakePeriod) <= daysStaked) {
            bigPayoutPool.add(amountAndInterest);
            return amountAndInterest;
        }
        
        return 0;
    }

    function totalStakers() public view returns(uint256){
        uint256 _totalStakers = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakers = _totalStakers.add(stakes[stakeholders[s]]);
        }
        return _totalStakers;
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
    
    function stakeOf(address account) public view returns(uint256) {
        return stakes[account];
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
    function bankersRoundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
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


