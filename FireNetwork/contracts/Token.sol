// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IToken.sol";

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
    address payable UNISWAP_ADDRESS = 0x849d89FfA8F91fF433A3A1D23865d15C8495Cc7B;
    address _owner;

    
    // Staking
    address public mainToken;
    address public auction;
    address public subBalances;
    
    // subBalances
    address public foreignSwap;
	address public bigPayDayPool;
	
	// Foreign swap
	address public signerAddress;
	
    // Auction init parameters
    address MANAGER_ADDRESS = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    address payable ETH_RECIPIENT = 0x4B346C42D212bBD0Bf85A01B1da80C2841149EA2;
    
    // HEX Params
    uint256 private constant AUTOSTAKE_PERIOD = 350;
    uint256 private constant MAX_CLAIM_AMOUNT = 10000000000000000000000000;
    uint256 private constant TOTAL_SNAPSHOT_AMOUNT = 370121420541683530700000000000;
    uint256 private constant TOTAL_SNAPSHOT_ADDRESSES = 183035;
    
    uint256 private _sessionsIds;
    uint256 private swapTokenBalance;
    uint256 public shareRate;
    uint256 public sharesTotalSupply;
    uint256 public nextPayoutCall;
    uint256 public stepTimestamp;
    uint256 public startContract;
    uint256 public globalPayout;
    uint256 public globalPayin;
	uint256 public startTimestamp;
    uint256 public basePeriod = 10;
    uint256 public lastAuctionEventId;
    //uint256 public start;
    uint256 public uniswapPercent;
    address public staking;
    uint256 public stakePeriod;
    uint256 public maxClaimAmount;
    address payable public uniswap;
    address payable public recipient;
    uint256[5] public poolYearAmounts;
    uint256[5] public PERIODS;
    uint256[5] public poolYearPercentages = [10, 15, 20, 25, 30]; // Percentages to pay out for each Big Pay Day
    bool[5] public poolTransferred;
    
    
    
    

    
    uint256 internal claimedAmount;
    uint256 internal totalSnapshotAmount;
    uint256 internal claimedAddresses;
    uint256 internal totalSnapshotAddresses;
    
    //uint256 private constant WEEKS = 50;
    //uint256 internal constant DAYS = WEEKS * 7;
    //uint256 private constant START_DAY = 1;
    //uint256 internal constant BIG_PAY_DAY = WEEKS + 1;
    uint256 internal constant secondsAday = 86400;
    uint256 internal constant blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time
    uint256 public constant PERCENT_DENOMINATOR = 100;
    
    
    
    
    

    
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Sent(address from, address to, uint amount);
    event Stake(address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end, uint256 shares);
    event Unstake( address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end, uint256 shares);
    event MakePayout( uint256 indexed value, uint256 indexed sharesTotalSupply, uint256 indexed time);
    event PoolCreated(uint256 paydayTime, uint256 poolAmount);
    event Bet(address indexed account, uint256 value, uint256 indexed auctionId, uint256 indexed time);
    event Withdraval(address indexed account, uint256 value, uint256 indexed auctionId, uint256 indexed time);
    event AuctionIsOver(uint256 eth, uint256 token, uint256 indexed auctionId);
    event TokensClaimed(address indexed account, uint256 indexed stepsFromStart, uint256 userAmount, uint256 penaltyuAmount);
        
    mapping(address => uint256) _balances;
    mapping(address => uint256) public claimedBalanceOf;
    mapping(address => uint256[]) public sessionsOf;
    mapping(address => uint256[]) public auctionsOf;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) _allowances;
    mapping(address => mapping(uint256 => Session)) public sessionDataOf;
    mapping(uint256 => mapping(address => UserBet)) public auctionBetOf;
    mapping(uint256 => mapping(address => bool)) public existAuctionsOf;
    mapping(uint256 => AuctionReserves) public reservesOf;
    
    
    // Users
    mapping (address => uint256[]) userStakings;
    mapping (uint256 => StakeSession) stakeSessions;
    
    struct Payout {uint256 payout; uint256 sharesTotalSupply;}
    struct Session { uint256 amount; uint256 start; uint256 end; uint256 shares; uint256 nextPayout;}
    struct StakeSession {address staker; uint256 shares; uint256 start;	uint256 end; uint256 finishTime; bool[5] payDayEligible; bool withdrawn;}
    struct SubBalance {uint256 totalShares; uint256 totalWithdrawAmount; uint256 payDayTime; uint256 requiredStakePeriod; bool minted;}
    struct AuctionReserves {uint256 eth; uint256 token; uint256 uniswapLastPrice; uint256 uniswapMiddlePrice;}
    struct UserBet {uint256 eth; address ref;}

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant EXTERNAL_STAKER_ROLE = keccak256("EXTERNAL_STAKER_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("CALLER_ROLE");
    bytes32 public constant SWAP_ROLE = keccak256("SWAP_ROLE");
    bytes32 public constant SUBBALANCE_ROLE = keccak256("SUBBALANCE_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");
    
    Payout[] public payouts;
    SubBalance[5] public subBalanceList;
    
    
    

	
    modifier onlyCaller() {
        require(
            hasRole(CALLER_ROLE, _msgSender()),
            "Caller is not a caller role"
        );
        _;
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not a caller role"
        );
        _;
    }

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

    constructor() public
    {
        _setupRole(SWAPPER_ROLE, msg.sender);
        _setupRole(SWAP_ROLE, FOREIGN_SWAP_ADDRESS);
        _setupRole(SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(EXTERNAL_STAKER_ROLE, FOREIGN_SWAP_ADDRESS);
        _setupRole(EXTERNAL_STAKER_ROLE, AUCTION_ADDRESS);
        _setupRole(STAKING_ROLE, STAKING_ADDRESS);
        _setupRole(CALLER_ROLE, FOREIGN_SWAP_ADDRESS);
        _setupRole(CALLER_ROLE, SUBBALANCES_ADDRESS);
        
        shareRate = 1e18;
        uniswapPercent = 20;
        stakePeriod = AUTOSTAKE_PERIOD;
        maxClaimAmount = MAX_CLAIM_AMOUNT;
        totalSnapshotAmount = TOTAL_SNAPSHOT_AMOUNT;
        totalSnapshotAddresses = TOTAL_SNAPSHOT_ADDRESSES;
        
        stepTimestamp = secondsAday;
        nextPayoutCall = now.add(secondsAday);
        startTimestamp = now;
        startContract = now;
        
        subBalances = SUBBALANCES_ADDRESS;
        mainToken = TOKEN_ADDRESS;
        auction = AUCTION_ADDRESS;
        foreignSwap = FOREIGN_SWAP_ADDRESS;
        staking = STAKING_ADDRESS;
        uniswap = UNISWAP_ADDRESS;
        bigPayDayPool = BPD_ADDRESS;
        recipient = ETH_RECIPIENT;
        
        signerAddress = msg.sender;
        //start = now;

    	for (uint256 i = 0; i < subBalanceList.length; i++) {
            PERIODS[i] = basePeriod.mul(i.add(1));
    		SubBalance storage subBalance = subBalanceList[i];
            subBalance.payDayTime = startTimestamp.add(stepTimestamp.mul(PERIODS[i]));
    		// subBalance.payDayEnd = subBalance.payDayStart.add(stepTimestamp);
            subBalance.requiredStakePeriod = PERIODS[i];
    	}
        
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

    function burn(address from, uint256 _value) public override returns(bool success) {
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[from] -= _value;            // Subtract from the sender
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

        emit Burn(msg.sender, amount);
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

        IToken(subBalances).callIncomeStakerTrigger(
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

        IToken(subBalances).callIncomeStakerTrigger(
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
            IToken(auction).callIncomeDailyTokensTrigger(amount);

            emit Unstake(
                msg.sender,
                sessionId,
                amount,
                sessionDataOf[msg.sender][sessionId].start,
                sessionDataOf[msg.sender][sessionId].end,
                shares
            );

            IToken(subBalances).callOutcomeStakerTrigger(
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
        IToken(auction).callIncomeDailyTokensTrigger(penalty);

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

        IToken(subBalances).callOutcomeStakerTrigger(
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

    function getSessionStats(uint256 sessionId) public view returns (address staker, uint256 shares, uint256 start, uint256 sessionEnd, bool withdrawn){
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
        uint256[5] memory bpdRawAmounts = IToken(bigPayDayPool).getPoolYearAmounts();
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
            IToken(mainToken).transfer(_msgSender(), payoutAmount);
        }

        if (penaltyAmount > 0) {
            IToken(mainToken).transfer(auction, penaltyAmount);
            IToken(auction).callIncomeDailyTokensTrigger(penaltyAmount);
        }
    }

    function callIncomeStakerTrigger(address staker, uint256 sessionId, uint256 start, uint256 end, uint256 shares) external override{
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

    function callOutcomeStakerTrigger(address staker, uint256 sessionId, uint256 start, uint256 end, uint256 shares) external override{
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
    	poolAmount = IToken(bigPayDayPool).transferYearlyPool(poolNumber);
    }

    // Pool logic
    function _bpdAmountFromRaw(uint256 yearTokenAmount) internal view returns (uint256 totalAmount, uint256 addAmount) {
    	uint256 currentTokenTotalSupply = IToken(mainToken).totalSupply();

        uint256 inflation = uint256(8).mul(currentTokenTotalSupply.add(currentSharesTotalSupply)).div(36500);

        
        uint256 criticalMassCoeff = IToken(foreignSwap).getCurrentClaimedAmount().mul(1e18).div(
            IToken(foreignSwap).getTotalSnapshotAmount());

       uint256 viralityCoeff = IToken(foreignSwap).getCurrentClaimedAddresses().mul(1e18).div(
            IToken(foreignSwap).getTotalSnapshotAddresses());

        uint256 totalUprisingCoeff = uint256(1e18).add(criticalMassCoeff).add(viralityCoeff);

        totalAmount = yearTokenAmount.add(inflation).mul(totalUprisingCoeff).div(1e18);
        addAmount = totalAmount.sub(yearTokenAmount);
    }
    
    
    // ------------------------------------------------------------------------
    //                              BPD
    // ------------------------------------------------------------------------

    function getPoolYearAmounts() external view override returns (uint256[5] memory poolAmounts) {
        return poolYearAmounts;
    }

    function getClosestPoolAmount() public view returns (uint256 poolAmount) {
         for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolTransferred[i]) {
                continue;
            } else {
                poolAmount = poolYearAmounts[i];
                return poolAmount;
            }

            // return 0;
        }
    }

    function callIncomeTokensTrigger(uint256 incomeAmountToken)external override{
        require(hasRole(SWAP_ROLE, _msgSender()), "Caller is not a swap role");

        // Divide income to years
        uint256 part = incomeAmountToken.div(PERCENT_DENOMINATOR);

        uint256 remainderPart = incomeAmountToken;
        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (i != poolYearAmounts.length - 1) {
                uint256 poolPart = part.mul(poolYearPercentages[i]);
                poolYearAmounts[i] = poolYearAmounts[i].add(poolPart);
                remainderPart = remainderPart.sub(poolPart);
            } else {
                poolYearAmounts[i] = poolYearAmounts[i].add(remainderPart);
            }
        }
    }

    function transferYearlyPool(uint256 poolNumber) external override returns (uint256 transferAmount) {
    	require(hasRole(SUBBALANCE_ROLE, _msgSender()), "Caller is not a subbalance role");

        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolNumber == i) {
                require(!poolTransferred[i], "Already transferred");
                transferAmount = poolYearAmounts[i];
                poolTransferred[i] = true;

                IToken(mainToken).transfer(_msgSender(), transferAmount);
                return transferAmount;
            }
        }
    }
    
    
    // ------------------------------------------------------------------------
    //                              Auction
    // ------------------------------------------------------------------------

    function auctionsOf_(address account) public view returns (uint256[] memory){
        return auctionsOf[account];
    }

    function setUniswapPercent(uint256 percent) external onlyManager {
        uniswapPercent = percent;
    }

    function getUniswapLastPrice() public view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(uniswap).WETH();
        path[1] = mainToken;

        uint256 price = IUniswapV2Router02(uniswap).getAmountsOut(
            1e18,
            path
        )[1];

        return price;
    }

    function getUniswapMiddlePriceForSevenDays() public view returns (uint256) {
        uint256 stepsFromStart = calculateStepsFromStart();

        uint256 index = stepsFromStart;
        uint256 sum;
        uint256 points;

        while (points != 7) {
            if (reservesOf[index].uniswapLastPrice != 0) {
                sum = sum.add(reservesOf[index].uniswapLastPrice);
                points = points.add(1);
            }

            if (index == 0) break;

            index = index.sub(1);
        }

        if (sum == 0) return getUniswapLastPrice();
        else return sum.div(points);
    }

    function _updatePrice() internal {
        uint256 stepsFromStart = calculateStepsFromStart();

        reservesOf[stepsFromStart].uniswapLastPrice = getUniswapLastPrice();

        reservesOf[stepsFromStart]
            .uniswapMiddlePrice = getUniswapMiddlePriceForSevenDays();
    }

    function bet(uint256 deadline, address ref) external payable {
        _saveAuctionData();
        _updatePrice();

        require(_msgSender() != ref, "msg.sender == ref");

        (
            uint256 toRecipient,
            uint256 toUniswap
        ) = _calculateRecipientAndUniswapAmountsToSend();

        _swapEth(toUniswap, deadline);

        uint256 stepsFromStart = calculateStepsFromStart();

        auctionBetOf[stepsFromStart][_msgSender()].ref = ref;

        auctionBetOf[stepsFromStart][_msgSender()]
            .eth = auctionBetOf[stepsFromStart][_msgSender()].eth.add(
            msg.value
        );

        if (!existAuctionsOf[stepsFromStart][_msgSender()]) {
            auctionsOf[_msgSender()].push(stepsFromStart);
            existAuctionsOf[stepsFromStart][_msgSender()] = true;
        }

        reservesOf[stepsFromStart].eth = reservesOf[stepsFromStart].eth.add(
            msg.value
        );

        recipient.transfer(toRecipient);

        emit Bet(msg.sender, msg.value, stepsFromStart, now);
    }

    function withdraw(uint256 auctionId) external {
        _saveAuctionData();
        _updatePrice();

        uint256 stepsFromStart = calculateStepsFromStart();

        require(stepsFromStart > auctionId, "auction is active");

        uint256 auctionETHUserBalance = auctionBetOf[auctionId][_msgSender()]
            .eth;

        auctionBetOf[auctionId][_msgSender()].eth = 0;

        require(auctionETHUserBalance > 0, "zero balance in auction");

        uint256 payout = _calculatePayout(auctionId, auctionETHUserBalance);

        uint256 uniswapPayoutWithPercent = _calculatePayoutWithUniswap(
            auctionId,
            auctionETHUserBalance,
            payout
        );

        if (payout > uniswapPayoutWithPercent) {
            uint256 nextWeeklyAuction = calculateNearestWeeklyAuction();

            reservesOf[nextWeeklyAuction].token = reservesOf[nextWeeklyAuction]
                .token
                .add(payout.sub(uniswapPayoutWithPercent));

            payout = uniswapPayoutWithPercent;
        }

        if (address(auctionBetOf[auctionId][_msgSender()].ref) == address(0)) {
            IToken(mainToken).burn(address(this), payout);

            IToken(staking).externalStake(payout, 14, _msgSender());

            emit Withdraval(msg.sender, payout, stepsFromStart, now);
        } else {
            IToken(mainToken).burn(address(this), payout);

            (
                uint256 toRefMintAmount,
                uint256 toUserMintAmount
            ) = _calculateRefAndUserAmountsToMint(payout);

            payout = payout.add(toUserMintAmount);

            IToken(staking).externalStake(payout, 14, _msgSender());

            emit Withdraval(msg.sender, payout, stepsFromStart, now);

            IToken(staking).externalStake(
                toRefMintAmount,
                14,
                auctionBetOf[auctionId][_msgSender()].ref
            );
        }
    }

    function callIncomeDailyTokensTrigger(uint256 amount) external override onlyCaller{
        uint256 stepsFromStart = calculateStepsFromStart();
        uint256 nextAuctionId = stepsFromStart.add(1);

        reservesOf[nextAuctionId].token = reservesOf[nextAuctionId].token.add(
            amount
        );
    }

    function callIncomeWeeklyTokensTrigger(uint256 amount) external override onlyCaller{
        uint256 nearestWeeklyAuction = calculateNearestWeeklyAuction();

        reservesOf[nearestWeeklyAuction]
            .token = reservesOf[nearestWeeklyAuction].token.add(amount);
    }

    function calculateNearestWeeklyAuction() public view returns (uint256) {
        uint256 stepsFromStart = calculateStepsFromStart();
        return stepsFromStart.add(uint256(7).sub(stepsFromStart.mod(7)));
    }

    //function calculateStepsFromStart() public view returns (uint256) {
        //return now.sub(start).div(stepTimestamp);
    //}

    function _calculatePayoutWithUniswap(uint256 auctionId, uint256 amount, uint256 payout) internal view returns (uint256) {
        uint256 uniswapPayout = reservesOf[auctionId]
            .uniswapMiddlePrice
            .mul(amount)
            .div(1e18);

        uint256 uniswapPayoutWithPercent = uniswapPayout.add(
            uniswapPayout.mul(uniswapPercent).div(100)
        );

        if (payout > uniswapPayoutWithPercent) {
            return uniswapPayoutWithPercent;
        } else {
            return payout;
        }
    }

    function _calculatePayout(uint256 auctionId, uint256 amount) internal view returns (uint256){
        return
            amount.mul(reservesOf[auctionId].token).div(
                reservesOf[auctionId].eth
            );
    }

    function _calculateRecipientAndUniswapAmountsToSend() private returns (uint256, uint256){
        uint256 toRecipient = msg.value.mul(20).div(100);
        uint256 toUniswap = msg.value.sub(toRecipient);

        return (toRecipient, toUniswap);
    }

    function _calculateRefAndUserAmountsToMint(uint256 amount) private pure returns (uint256, uint256){
        uint256 toRefMintAmount = amount.mul(20).div(100);
        uint256 toUserMintAmount = amount.mul(10).div(100);

        return (toRefMintAmount, toUserMintAmount);
    }

    function _swapEth(uint256 amount, uint256 deadline) private {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(uniswap).WETH();
        path[1] = mainToken;

        IUniswapV2Router02(uniswap).swapExactETHForTokens{value: amount}(
            0,
            path,
            staking,
            deadline
        );
    }

    function _saveAuctionData() internal {
        uint256 stepsFromStart = calculateStepsFromStart();
        AuctionReserves memory reserves = reservesOf[stepsFromStart];

        if (lastAuctionEventId < stepsFromStart) {
            emit AuctionIsOver(reserves.eth, reserves.token, stepsFromStart);
            lastAuctionEventId = stepsFromStart;
        }
    }
    
    
    // ------------------------------------------------------------------------
    //                              ForeignSwap
    // ------------------------------------------------------------------------
    

    function getCurrentClaimedAmount() external override view returns (uint256){
        return claimedAmount;
    }

    function getTotalSnapshotAmount() external override view returns (uint256) {
        return totalSnapshotAmount;
    }

    function getCurrentClaimedAddresses() external override view returns (uint256){
        return claimedAddresses;
    }

    function getTotalSnapshotAddresses() external override view returns (uint256){
        return totalSnapshotAddresses;
    }

    function getMessageHash(uint256 amount, address account) public pure returns (bytes32){
        return keccak256(abi.encode(amount, account));
    }

    function check(uint256 amount, bytes memory signature) public view returns (bool){
        bytes32 messageHash = getMessageHash(amount, address(msg.sender));
        return ECDSA.recover(messageHash, signature) == signerAddress;
    }

    function getUserClaimableAmountFor(uint256 amount) public view returns (uint256, uint256){
        if (amount > 0) {
            (
                uint256 amountOut,
                uint256 delta,
                uint256 deltaAuctionWeekly
            ) = getClaimableAmount(amount);
            uint256 deltaPenalized = delta.add(deltaAuctionWeekly);
            return (amountOut, deltaPenalized);
        } else {
            return (0, 0);
        }
    }

    function claimFromForeign(uint256 amount, bytes memory signature) public returns (bool){
        require(amount > 0, "CLAIM: amount <= 0");
        require(
            check(amount, signature),
            "CLAIM: cannot claim because signature is not correct"
        );
        require(claimedBalanceOf[msg.sender] == 0, "CLAIM: cannot claim twice");

        (
            uint256 amountOut,
            uint256 delta,
            uint256 deltaAuctionWeekly
        ) = getClaimableAmount(amount);

        uint256 deltaPart = delta.div(stakePeriod);
        uint256 deltaAuctionDaily = deltaPart.mul(stakePeriod.sub(uint256(1)));

        IToken(mainToken).mint(auction, deltaAuctionDaily);
        IToken(auction).callIncomeDailyTokensTrigger(deltaAuctionDaily);

        if (deltaAuctionWeekly > 0) {
            IToken(mainToken).mint(auction, deltaAuctionWeekly);
            IToken(auction).callIncomeWeeklyTokensTrigger(deltaAuctionWeekly);
        }

        IToken(mainToken).mint(bigPayDayPool, deltaPart);
        IToken(bigPayDayPool).callIncomeTokensTrigger(deltaPart);
        IToken(staking).externalStake(amountOut, stakePeriod, msg.sender);

        claimedBalanceOf[msg.sender] = amount;
        claimedAmount = claimedAmount.add(amount);
        claimedAddresses = claimedAddresses.add(uint256(1));

        emit TokensClaimed(msg.sender, calculateStepsFromStart(), amountOut, deltaPart);

        return true;
    }

    function calculateStepsFromStart() public view returns (uint256) {
        uint256 start = now;
        return (now.sub(start)).div(stepTimestamp);
    }

    // function calculateStakeEndTime(uint256 startTime) internal view returns (uint256) {
    //     uint256 stakePeriod = stepTimestamp.mul(stakePeriod);
    //     return  startTime.add(stakePeriod);
    // }

    function getClaimableAmount(uint256 amount) internal view returns (uint256, uint256, uint256){
        uint256 deltaAuctionWeekly = 0;
        if (amount > maxClaimAmount) {
            deltaAuctionWeekly = amount.sub(maxClaimAmount);
            amount = maxClaimAmount;
        }

        uint256 stepsFromStart = calculateStepsFromStart();
        uint256 daysPassed = stepsFromStart > stakePeriod ? stakePeriod : stepsFromStart;
        uint256 delta = amount.mul(daysPassed).div(stakePeriod);
        uint256 amountOut = amount.sub(delta);

        return (amountOut, delta, deltaAuctionWeekly);
    }
}