// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/ISubBalances.sol";

    // ------------------------------------------------------------------------
    //                              Main Token Contract
    // ------------------------------------------------------------------------
contract Token is Context, IToken, AccessControl {
    using SafeMath for uint256;
    
    string public constant name = "FIRE Network";
    string public constant symbol = "FIRE";
    uint8 internal constant decimals = 18;
    
    uint256 public constant LIMIT = 250000000000e18;
    uint256 public constant RATE = 1e6;
    
    uint256  _totalSupply = 21000000e18; //21m
    uint256 premineTotal_ = 10250000e18; // 10.25m coins total on launch
    uint256  _circulatingSupply = 0; //Set to 0 at start
    uint256 public currentSharesTotalSupply;
    
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
    
    // Staking
    address public mainToken;
    address public auction;
    address public subBalances;
    
    // subBalances
    address public foreignSwap;
	address public bigPayDayPool;
	
    // Auction init parameters
    address MANAGER_ADDRESS = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    address ETH_RECIPIENT = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    
    // HEX Params
    uint256 private constant AUTOSTAKE_PERIOD = 350;
    uint256 private constant MAX_CLAIM_AMOUNT = 10000000000000000000000000;
    uint256 private constant TOTAL_SNAPSHOT_AMOUNT = 370121420541683530700000000000;
    uint256 private constant TOTAL_SNAPSHOT_ADDRESSES = 183035;
    uint256 public constant _stepTimestamp = 86400;
    uint256 private _sessionsIds;

    uint256 public shareRate;
    uint256 public sharesTotalSupply;
    uint256 public nextPayoutCall;
    uint256 public stepTimestamp;
    uint256 public startContract;
    uint256 public globalPayout;
    uint256 public globalPayin;
	uint256 public startTimestamp;
    uint256 public basePeriod;
    uint256[5] public PERIODS;


    
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Sent(address from, address to, uint amount);
    event Stake(address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end, uint256 shares);
    event Unstake( address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end, uint256 shares);
    event MakePayout( uint256 indexed value, uint256 indexed sharesTotalSupply, uint256 indexed time);
    event PoolCreated(uint256 paydayTime, uint256 poolAmount);
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) _allowances;
    mapping(address => mapping(uint256 => Session)) public sessionDataOf;
    mapping(address => uint256[]) public sessionsOf;
    
    // Users
    mapping (address => uint256[]) userStakings;
    mapping (uint256 => StakeSession) stakeSessions;
    
    struct Payout {uint256 payout; uint256 sharesTotalSupply;}
    struct Session { uint256 amount; uint256 start; uint256 end; uint256 shares; uint256 nextPayout;}
    struct StakeSession {address staker; uint256 shares; uint256 start;	uint256 end; uint256 finishTime; bool[5] payDayEligible; bool withdrawn;}
    struct SubBalance {uint256 totalShares; uint256 totalWithdrawAmount; uint256 payDayTime; uint256 requiredStakePeriod; bool minted;}

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant EXTERNAL_STAKER_ROLE = keccak256("EXTERNAL_STAKER_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("CALLER_ROLE");
    
    Payout[] public payouts;
    SubBalance[5] public subBalanceList;
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
    
    modifier onlyExternalStaker() {
        require(
            hasRole(EXTERNAL_STAKER_ROLE, _msgSender()),
            "Caller is not a external staker"
        );
        _;
    }
    
    constructor(address _setter) public {
        _setupRole(SETTER_ROLE, _setter);
    }

    constructor() public
    {
        _setupRole(SWAPPER_ROLE, msg.sender);
        _setupRole(SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(EXTERNAL_STAKER_ROLE, FOREIGN_SWAP_ADDRESS);
        _setupRole(EXTERNAL_STAKER_ROLE, AUCTION_ADDRESS);
        
        shareRate = 1e18;
        stepTimestamp = _stepTimestamp;
        nextPayoutCall = now.add(_stepTimestamp);
        startContract = now;
        
        subBalances = SUBBALANCES_ADDRESS;
        mainToken = TOKEN_ADDRESS;
        auction = AUCTION_ADDRESS;
        
        _circulatingSupply = _circulatingSupply.add(premineTotal_);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() public view override returns (uint256) {
        return _circulatingSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) public override returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= _balances[owner]);
        require(numTokens <= _allowances[owner][msg.sender]);
        _balances[owner] = _balances[owner].sub(numTokens);
        _allowances[owner][msg.sender] = _allowances[owner][msg.sender].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function send(address Send_To, uint amount) public {
        require(amount <= _balances[msg.sender], "Insufficient balance.");
        _balances[msg.sender] -= amount;
        _balances[Send_To] += amount;
        emit Sent(msg.sender, Send_To, amount);
    }

    function mint(address Mint_To, uint amount) external override onlyMinter {
        _balances[Mint_To] += amount;
        _circulatingSupply = _circulatingSupply.add(amount);
    }

    function burn(uint256 _value) public override returns(bool success) {
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                     // Updates totalSupply
        _circulatingSupply -= _value;               // Update circulating supply
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        _allowances[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // ------------------------------------------------------------------------
    //                              Get Roles
    // ------------------------------------------------------------------------

    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSwapperRole() external pure returns (bytes32) {
        return SWAPPER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }
    
    // ------------------------------------------------------------------------
    //                              Staking
    // ------------------------------------------------------------------------
    
    function sessionsOf_(address account) external view returns (uint256[] memory){
        return sessionsOf[account];
    }

    function stake(uint256 amount, uint256 stakingDays) external {
        if (now >= nextPayoutCall) makePayout();

        require(stakingDays > 0, "stakingDays < 1");

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        Burn(msg.sender, amount);
        _sessionsIds = _sessionsIds.add(1);
        uint256 sessionId = _sessionsIds;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            nextPayout: payouts.length
        });

        sessionsOf[msg.sender].push(sessionId);

        ISubBalances(subBalances).callIncomeStakerTrigger(
            msg.sender,
            sessionId,
            start,
            end,
            shares
        );

        emit Stake(msg.sender, sessionId, amount, start, end, shares);
    }
    
    function externalStake(uint256 amount, uint256 stakingDays, address staker) external override onlyExternalStaker {
        if (now >= nextPayoutCall) makePayout();

        require(stakingDays > 0, "stakingDays < 1");

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        _sessionsIds = _sessionsIds.add(1);
        uint256 sessionId = _sessionsIds;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[staker][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            nextPayout: payouts.length
        });

        sessionsOf[staker].push(sessionId);

        ISubBalances(subBalances).callIncomeStakerTrigger(
            staker,
            sessionId,
            start,
            end,
            shares
        );

        emit Stake(staker, sessionId, amount, start, end, shares);
    }
    
    function unstake(uint256 sessionId) external {
        if (now >= nextPayoutCall) makePayout();

        require(
            sessionDataOf[msg.sender][sessionId].shares > 0,
            "NativeSwap: Shares balance is empty"
        );

        uint256 shares = sessionDataOf[msg.sender][sessionId].shares;

        sessionDataOf[msg.sender][sessionId].shares = 0;

        if (sessionDataOf[msg.sender][sessionId].nextPayout >= payouts.length) {
            // To auction
            uint256 amount = sessionDataOf[msg.sender][sessionId].amount;

            _initPayout(auction, amount);
            IAuction(auction).callIncomeDailyTokensTrigger(amount);

            emit Unstake(
                msg.sender,
                sessionId,
                amount,
                sessionDataOf[msg.sender][sessionId].start,
                sessionDataOf[msg.sender][sessionId].end,
                shares
            );

            ISubBalances(subBalances).callOutcomeStakerTrigger(
                msg.sender,
                sessionId,
                sessionDataOf[msg.sender][sessionId].start,
                sessionDataOf[msg.sender][sessionId].end,
                shares
            );


            return;
        }

        uint256 stakingInterest = calculateStakingInterest(
            sessionId,
            msg.sender,
            shares
        );

        _updateShareRate(msg.sender, shares, stakingInterest, sessionId);

        sharesTotalSupply = sharesTotalSupply.sub(shares);

        (uint256 amountOut, uint256 penalty) = getAmountOutAndPenalty(
            sessionId,
            stakingInterest
        );

        // To auction
        _initPayout(auction, penalty);
        IAuction(auction).callIncomeDailyTokensTrigger(penalty);

        // To account
        _initPayout(msg.sender, amountOut);

        emit Unstake(
            msg.sender,
            sessionId,
            amountOut,
            sessionDataOf[msg.sender][sessionId].start,
            sessionDataOf[msg.sender][sessionId].end,
            shares
        );

        ISubBalances(subBalances).callOutcomeStakerTrigger(
            msg.sender,
            sessionId,
            sessionDataOf[msg.sender][sessionId].start,
            sessionDataOf[msg.sender][sessionId].end,
            sessionDataOf[msg.sender][sessionId].shares
        );
    }
    
    function calculateStakingInterest( uint256 sessionId, address account, uint256 shares) public view returns (uint256) {
        uint256 stakingInterest;

        for (
            uint256 i = sessionDataOf[account][sessionId].nextPayout;
            i < payouts.length;
            i++
        ) {
            uint256 payout = payouts[i].payout.mul(shares).div(
                payouts[i].sharesTotalSupply
            );

            stakingInterest = stakingInterest.add(payout);
        }

        return stakingInterest;
    }
    
    function _updateShareRate(address account, uint256 shares, uint256 stakingInterest, uint256 sessionId) internal {
        uint256 newShareRate = _getShareRate(
            sessionDataOf[account][sessionId].amount,
            shares,
            sessionDataOf[account][sessionId].start,
            sessionDataOf[account][sessionId].end,
            stakingInterest
        );

        if (newShareRate > shareRate) {
            shareRate = newShareRate;
        }
    }
    
    function _initPayout(address to, uint256 amount) internal {
        IToken(mainToken).mint(to, amount);
        globalPayout = globalPayout.add(amount);
    }
    
    function getAmountOutAndPenalty(uint256 sessionId, uint256 stakingInterest) public view returns (uint256, uint256){
        uint256 stakingDays = (
            sessionDataOf[msg.sender][sessionId].end.sub(
                sessionDataOf[msg.sender][sessionId].start
            )
        )
            .div(stepTimestamp);

        uint256 daysStaked = (
            now.sub(sessionDataOf[msg.sender][sessionId].start)
        )
            .div(stepTimestamp);

        uint256 amountAndInterest = sessionDataOf[msg.sender][sessionId]
            .amount
            .add(stakingInterest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount = amountAndInterest.mul(daysStaked).div(
                stakingDays
            );

            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, earlyUnstakePenalty);
            // In time
        } else if (
            stakingDays <= daysStaked && daysStaked < stakingDays.add(14)
        ) {
            return (amountAndInterest, 0);
            // Late
        } else if (
            stakingDays.add(14) <= daysStaked &&
            daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);

            uint256 payOutAmount = amountAndInterest
                .mul(uint256(714).sub(daysAfterStaking))
                .div(700);

            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, lateUnstakePenalty);
            // Nothing
        } else if (stakingDays.add(714) <= daysStaked) {
            return (0, amountAndInterest);
        }

        return (0, 0);
    }
    
    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }
    function getNow0x() external view returns (uint256) {
        return now;
    }

    function makePayout() public {
        require(now >= nextPayoutCall, "NativeSwap: Wrong payout time");

        uint256 payout = _getPayout();

        payouts.push(
            Payout({payout: payout, sharesTotalSupply: sharesTotalSupply})
        );

        nextPayoutCall = nextPayoutCall.add(stepTimestamp);

        emit MakePayout(payout, sharesTotalSupply, now);
    }

    function readPayout() external view returns (uint256) {
        uint256 amountTokenInDay = IToken(mainToken).balanceOf(address(this));

        uint256 currentTokenTotalSupply = (IToken(mainToken).totalSupply()).add(
            globalPayin
        );

        uint256 inflation = uint256(8)
            .mul(currentTokenTotalSupply.add(sharesTotalSupply))
            .div(36500);

        return amountTokenInDay.add(inflation);
    }

    function _getPayout() internal returns (uint256) {
        uint256 amountTokenInDay = IToken(mainToken).balanceOf(address(this));

        globalPayin = globalPayin.add(amountTokenInDay);

        if (globalPayin > globalPayout) {
            globalPayin = globalPayin.sub(globalPayout);
            globalPayout = 0;
        } else {
            globalPayin = 0;
            globalPayout = 0;
        }

        uint256 currentTokenTotalSupply = (IToken(mainToken).totalSupply()).add(
            globalPayin
        );

        Burn(address(this), amountTokenInDay);

        uint256 inflation = uint256(8)
            .mul(currentTokenTotalSupply.add(sharesTotalSupply))
            .div(36500);

        globalPayin = globalPayin.add(inflation);

        return amountTokenInDay.add(inflation);
    }

    function _getStakersSharesAmount(uint256 amount, uint256 start, uint256 end) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);
        uint256 numerator = amount.mul(uint256(1819).add(stakingDays));
        uint256 denominator = uint256(1820).mul(shareRate);

        return (numerator).mul(1e18).div(denominator);
    }

    function _getShareRate(uint256 amount, uint256 shares, uint256 start, uint256 end, uint256 stakingInterest) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

        uint256 numerator = (amount.add(stakingInterest)).mul(
            uint256(1819).add(stakingDays)
        );

        uint256 denominator = uint256(1820).mul(shares);

        return (numerator).mul(1e18).div(denominator);
    }


    // ------------------------------------------------------------------------
    //                              subBalances
    // ------------------------------------------------------------------------
    
       















    function init(
        address _foreignSwap,
        address _bigPayDayPool,
        address _auction,
        address _staking,
        uint256 _basePeriod
    ) public
      onlySetter
    {
        _setupRole(STAKING_ROLE, _staking);
        foreignSwap = _foreignSwap;
        bigPayDayPool = _bigPayDayPool;
        auction = _auction;
        stepTimestamp = _stepTimestamp;
        basePeriod = _basePeriod;
    	startTimestamp = now;

    	for (uint256 i = 0; i < subBalanceList.length; i++) {
            PERIODS[i] = _basePeriod.mul(i.add(1));
    		SubBalance storage subBalance = subBalanceList[i];
            subBalance.payDayTime = startTimestamp.add(stepTimestamp.mul(PERIODS[i]));
    		// subBalance.payDayEnd = subBalance.payDayStart.add(stepTimestamp);
            subBalance.requiredStakePeriod = PERIODS[i];
    	}
        renounceRole(SETTER_ROLE, _msgSender());
    }

    function getStartTimes() public view returns (uint256[5] memory startTimes) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            startTimes[i] = subBalanceList[i].payDayTime;
        }
    }

    function getPoolsMinted() public view returns (bool[5] memory poolsMinted) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            poolsMinted[i] = subBalanceList[i].minted;
        }
    }

    function getPoolsMintedAmounts() public view returns (uint256[5] memory poolsMintedAmounts) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            poolsMintedAmounts[i] = subBalanceList[i].totalWithdrawAmount;
        }
    }

    function getClosestYearShares() public view returns (uint256 shareAmount) {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            if (!subBalanceList[i].minted) {
                continue;
            } else {
                shareAmount = subBalanceList[i].totalShares;
                return shareAmount;
            }

            // return 0;
        }
    }

    function getSessionStats(uint256 sessionId) 
        public 
        view 
        returns (address staker, uint256 shares, uint256 start, uint256 sessionEnd, bool withdrawn) 
    {
        StakeSession storage stakeSession = stakeSessions[sessionId];
        staker = stakeSession.staker;
        shares = stakeSession.shares;
        start = stakeSession.start;
        if (stakeSession.finishTime > 0) {
            sessionEnd = stakeSession.finishTime;
        } else {
            sessionEnd = stakeSession.end;
        }
        withdrawn = stakeSession.withdrawn;
    }

    function getSessionEligibility(uint256 sessionId) public view returns (bool[5] memory stakePayDays) {
        StakeSession storage stakeSession = stakeSessions[sessionId];
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            stakePayDays[i] = stakeSession.payDayEligible[i];
        }
    }


    function calculateSessionPayout(uint256 sessionId) public view returns (uint256, uint256) {
        StakeSession storage stakeSession = stakeSessions[sessionId];

        uint256 subBalancePayoutAmount;
        uint256[5] memory bpdRawAmounts = IBPD(bigPayDayPool).getPoolYearAmounts();
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            SubBalance storage subBalance = subBalanceList[i];

            uint256 subBalanceAmount;
            uint256 addAmount;
            if (subBalance.minted) {
                subBalanceAmount = subBalance.totalWithdrawAmount;
            } else {
                (subBalanceAmount, addAmount) = _bpdAmountFromRaw(bpdRawAmounts[i]);
            }
            if (stakeSession.payDayEligible[i]) {
                uint256 stakerShare = stakeSession.shares.mul(1e18).div(subBalance.totalShares);
                uint256 stakerAmount = subBalanceAmount.mul(stakerShare).div(1e18);
                subBalancePayoutAmount = subBalancePayoutAmount.add(stakerAmount);
            }
        }

        uint256 stakingDays = stakeSession.end.sub(stakeSession.start).div(stepTimestamp);
        uint256 stakeEnd;
        if (stakeSession.finishTime != 0) {
            stakeEnd = stakeSession.finishTime;
        } else {
            stakeEnd = stakeSession.end;
        }

        uint256 daysStaked = stakeEnd.sub(stakeSession.start).div(stepTimestamp);

        // Early unstaked
        if (stakingDays > daysStaked) {
            uint256 payoutAmount = subBalancePayoutAmount.mul(daysStaked).div(stakingDays);
            uint256 earlyUnstakePenalty = subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, earlyUnstakePenalty);
        // Unstaked in time, no penalty
        } else if (
            stakingDays <= daysStaked && daysStaked < stakingDays.add(14)
        ) {
            return (subBalancePayoutAmount, 0);
        // Unstaked late
        } else if (
            stakingDays.add(14) <= daysStaked && daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);
            uint256 payoutAmount = subBalancePayoutAmount.mul(uint256(714).sub(daysAfterStaking)).div(700);
            uint256 lateUnstakePenalty = subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, lateUnstakePenalty);
        // Too much time 
        } else if (stakingDays.add(714) <= daysStaked) {
            return (0, subBalancePayoutAmount);
        }

        return (0, 0);
    }

    function withdrawPayout(uint256 sessionId) public {
        StakeSession storage stakeSession = stakeSessions[sessionId];

        require(stakeSession.finishTime != 0, "cannot withdraw before unclaim");
        require(!stakeSession.withdrawn, "already withdrawn");
        require(_msgSender() == stakeSession.staker, "caller not matching sessionId");
        (uint256 payoutAmount, uint256 penaltyAmount) = calculateSessionPayout(sessionId);

        stakeSession.withdrawn = true;

        if (payoutAmount > 0) {
            IERC20(mainToken).transfer(_msgSender(), payoutAmount);
        }

        if (penaltyAmount > 0) {
            IERC20(mainToken).transfer(auction, penaltyAmount);
            IAuction(auction).callIncomeDailyTokensTrigger(penaltyAmount);
        }
    }


    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external override {
        require(hasRole(STAKING_ROLE, _msgSender()), "SUBBALANCES: Caller is not a staking role");
        require(end > start, 'SUBBALANCES: Stake end must be after stake start');
        uint256 stakeDays = end.sub(start).div(stepTimestamp);

        // Skipping user if period less that year
        if (stakeDays >= basePeriod) {

            // Setting pay day eligibility for user in advance when he stakes
            bool[5] memory stakerPayDays;
            for (uint256 i = 0; i < subBalanceList.length; i++) {
                SubBalance storage subBalance = subBalanceList[i];  

                // Setting eligibility only if payday is not passed and stake end more that this pay day
                if (subBalance.payDayTime > start && end > subBalance.payDayTime) {
                    stakerPayDays[i] = true;

                    subBalance.totalShares = subBalance.totalShares.add(shares);
                }

            }

            // Saving user
            stakeSessions[sessionId] = StakeSession({
                staker: staker,
                shares: shares,
                start: start,
                end: end,
                finishTime: 0,
                payDayEligible: stakerPayDays,
                withdrawn: false
            });
            userStakings[staker].push(sessionId);

        }

        // Adding to shares
        currentSharesTotalSupply = currentSharesTotalSupply.add(shares);            

	}

    function callOutcomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) 
        external
        override
    {
        (staker);
        require(hasRole(STAKING_ROLE, _msgSender()), "SUBBALANCES: Caller is not a staking role");
        require(end > start, 'SUBBALANCES: Stake end must be after stake start');
        uint256 stakeDays = end.sub(start).div(stepTimestamp);
        uint256 realStakeEnd = now;
        // uint256 daysStaked = realStakeEnd.sub(stakeStart).div(stepTimestamp);

        if (stakeDays >= basePeriod) {
            StakeSession storage stakeSession = stakeSessions[sessionId];

            // Rechecking eligibility of paydays
            for (uint256 i = 0; i < subBalanceList.length; i++) {
                SubBalance storage subBalance = subBalanceList[i];  

                // Removing from payday if unstaked before
                if (realStakeEnd < subBalance.payDayTime) {
                    bool wasEligible = stakeSession.payDayEligible[i];
                    stakeSession.payDayEligible[i] = false;

                    if (wasEligible) {
                        if (shares > subBalance.totalShares) {
                           subBalance.totalShares = 0;
                        } else {
                            subBalance.totalShares = subBalance.totalShares.sub(shares);
                        }
                    }
                }
            }


            // Setting real stake end
            stakeSessions[sessionId].finishTime = realStakeEnd;

        }

        // Substract shares from total
        if (shares > currentSharesTotalSupply) {
            currentSharesTotalSupply = 0;
        } else {
            currentSharesTotalSupply = currentSharesTotalSupply.sub(shares);
        }

    }


    // Pool logic
    function generatePool() external returns (bool) {
    	for (uint256 i = 0; i < subBalanceList.length; i++) {
    		SubBalance storage subBalance = subBalanceList[i];

    		if (now > subBalance.payDayTime && !subBalance.minted) {
    			uint256 yearTokens = getPoolFromBPD(i);
    			(uint256 bpdTokens, uint256 addAmount) = _bpdAmountFromRaw(yearTokens);

    			IToken(mainToken).mint(address(this), addAmount);
    			subBalance.totalWithdrawAmount = bpdTokens;
    			subBalance.minted = true;

                emit PoolCreated(now, bpdTokens);
                return true;
    		}
    	}
    }


    // Pool logic
    function getPoolFromBPD(uint256 poolNumber) internal returns (uint256 poolAmount) {
    	poolAmount = IBPD(bigPayDayPool).transferYearlyPool(poolNumber);
    }

    // Pool logic
    function _bpdAmountFromRaw(uint256 yearTokenAmount) internal view returns (uint256 totalAmount, uint256 addAmount) {
    	uint256 currentTokenTotalSupply = IERC20(mainToken).totalSupply();

        uint256 inflation = uint256(8).mul(currentTokenTotalSupply.add(currentSharesTotalSupply)).div(36500);

        
        uint256 criticalMassCoeff = IForeignSwap(foreignSwap).getCurrentClaimedAmount().mul(1e18).div(
            IForeignSwap(foreignSwap).getTotalSnapshotAmount());

       uint256 viralityCoeff = IForeignSwap(foreignSwap).getCurrentClaimedAddresses().mul(1e18).div(
            IForeignSwap(foreignSwap).getTotalSnapshotAddresses());

        uint256 totalUprisingCoeff = uint256(1e18).add(criticalMassCoeff).add(viralityCoeff);

        totalAmount = yearTokenAmount.add(inflation).mul(totalUprisingCoeff).div(1e18);
        addAmount = totalAmount.sub(yearTokenAmount);
    }
}