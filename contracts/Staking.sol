
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IToken.sol";

contract Staking is AccessControl {
    using SafeMath for uint256;

    // Time based variables
    uint256 unlockTime;

    uint256 public totalStakers = 0;
    uint256 public totalStakes = 0;

      // Premine values
  uint256 premineTotal = 676000000000e18; // 675b coins total on launch
  uint256 presalePremine = 250000000000e18; // 250b coins
  uint256 devPayment = 1000000000e18; // 1b coins
  uint256 swapPremine = 250000000000e18; // 250b coins
  uint256 uinswapPremine = 75000000000e18; // 75b coins
  uint256 devFundPremine = 75000000000e18; // 75b coins
  uint256 teamPremine = 25000000000e18; // 25b coins
  uint256 public bigPayoutPool = 1500000; //1m coins
    
  address internal constant _advisorAddress_1 = 0x583031D1113aD414F02576BD6afaBfb302140225;
  address internal constant _advisorAddress_2 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _advisorAddress_3 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _advisorAddress_4 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _advisorAddress_5 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  uint256 internal constant _advisorPercent = 100; // 1% in basis points
    
  address internal constant _coreTeamAddress_1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
  address internal constant _coreTeamAddress_2 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _coreTeamAddress_3 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _coreTeamAddress_4 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  address internal constant _coreTeamAddress_5 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  uint256 internal constant _coreTeamPercent = 500; // 5% in basis points
    
  address internal constant _marketingAddress = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
  uint256 internal constant _marketingPercent = 100; // 1% in basis points
    
  uint256 internal constant _burnTransferPercent = 2; // .02% in basis points
  uint256 internal constant _burnEarlyEndStakePercent = 3000; // 30% in basis points
  uint256 internal constant _bpdEarlyEndStakePercent = 3000; // 30% in basis points

    uint256 internal constant days_year = 365;
    uint256 internal constant secondsAday = 86400;
    uint256 internal constant blocksAday = 6500; // Rough rounded up blocks perday based on 14sec eth block time
    uint256 internal _unStakeGracePeriod = 14; // Amount in days
    uint256 internal _maxUnstakePeriod = 365; // Amount in days

    uint256 private _sessionsIds;

    event stake(address indexed account, uint256 indexed sessionId, uint256 amount, uint256 start, uint256 end);

    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    
    mapping(address => stakeData) stakeParams;
    mapping(uint256 => stakeData) sessionStakeData;

    address[] internal stakeholders;

    address public mainToken;    
    bool public init_;

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
        init_ = false;
    }

    function init(
        address _mainToken
    ) external {
        mainToken = _mainToken;
        init_ = true;
    }

    function createStake(uint256 amount, uint256 stakingDays) public returns (uint256){
        require(IERC20(mainToken).balanceOf(msg.sender) >= amount, "You can only stake what you own.");
        require(stakingDays > 0, "stakingDays < 1");
        totalStakes = totalStakes.add(amount);
        IToken(mainToken).burn(msg.sender, amount);
        
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
        //_stakingSupply.add(amount);
        
        //If user is not already in the stakes array add them for bpd payouts
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        //stakes[msg.sender] = stakes[msg.sender].add(amount);
        
        
        
        emit stake(msg.sender, sessionId, amount, now, unlockTime);
        
        return (sessionId);
    }

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

    function claimableAmount(uint256 sessionID) internal returns (uint256){
        require(now.sub(sessionStakeData[sessionID].start) > secondsAday, "You must have been staked for 1 full day first.");
        
        //uint256 actualDaysStaked = now.sub(sessionStakeData[sessionID].start);
        uint256 actualDaysStaked = sessionStakeData[sessionID].end.sub(sessionStakeData[sessionID].start).div(60).div(60).div(24);
        uint256 commitedDaysToStake = now.sub(sessionStakeData[sessionID].start).div(60).div(60).div(24);
        //uint256 timeForFullReward = sessionStakeData[sessionID].end.sub(sessionStakeData[sessionID].start);
        
        uint256 amountAndInterest = sessionStakeData[sessionID].amount.add(sessionStakeData[sessionID].interest);
        
        
        //uint256 commitedDaysToStake = saidStakedDays;
        //uint256 actualDaysStaked = actualStakedDays;
        //uint256 timeForFullReward = actualStakedDays.add(_unStakeGracePeriod);
        
        //uint256 amountAndInterest = amount;
        
        uint256 payOutAmount;
        uint256 penalty;
        
        // ------------------------------------------------------------------------
        //                             Claimed to early
        // ------------------------------------------------------------------------
        
        if (commitedDaysToStake > actualDaysStaked) {
            payOutAmount = amountAndInterest.mul(actualDaysStaked).div(commitedDaysToStake);
             penalty = amountAndInterest.sub(payOutAmount);
            
        // ------------------------------------------------------------------------
        //              Claimed on time and under endStake grace period
        // ------------------------------------------------------------------------
        
        } else if (actualDaysStaked >= commitedDaysToStake && actualDaysStaked <= commitedDaysToStake.add(_unStakeGracePeriod)) {
            payOutAmount = amountAndInterest;
            penalty = 0;
            
        // ------------------------------------------------------------------------
        //             Claimed after endStake grace period with penalties
        // ------------------------------------------------------------------------
        
        } else if (actualDaysStaked > commitedDaysToStake.add(_unStakeGracePeriod) && actualDaysStaked < commitedDaysToStake.add(_maxUnstakePeriod)) {
            penalty = amountAndInterest.mul(actualDaysStaked).div(_maxUnstakePeriod);
            payOutAmount = amountAndInterest.sub(penalty);
            
        // ------------------------------------------------------------------------
        //             Claimed to late all funds are moved to BPD pool
        // ------------------------------------------------------------------------
        
        } else if (commitedDaysToStake.add(_maxUnstakePeriod) <= actualDaysStaked) {
            penalty = amountAndInterest;
            payOutAmount = 0;

        }
        
            uint256 coreTeamPayout = penalty.mul(_coreTeamPercent).div(10000);
            uint256 advisorPayout = penalty.mul(_advisorPercent).div(10000);
            uint256 marketingPayout = penalty.mul(_marketingPercent).div(10000);
            //uint256 burnAmount = penalty.mul(_burnEarlyEndStakePercent).div(10000);
            uint256 bpdPoolAmount = penalty.mul(_bpdEarlyEndStakePercent).div(10000);
            
            if (coreTeamPayout > 1 && penalty > 0){
                IERC20(mainToken).transfer(_coreTeamAddress_1, coreTeamPayout); IERC20(mainToken).transfer(_coreTeamAddress_2, coreTeamPayout);
                IERC20(mainToken).transfer(_coreTeamAddress_3, coreTeamPayout); IERC20(mainToken).transfer(_coreTeamAddress_4, coreTeamPayout);
                IERC20(mainToken).transfer(_coreTeamAddress_5, coreTeamPayout);
            } 
            if (advisorPayout > 1 && penalty > 0){
                IERC20(mainToken).transfer(_advisorAddress_1, advisorPayout); IERC20(mainToken).transfer(_advisorAddress_2, advisorPayout);
                IERC20(mainToken).transfer(_advisorAddress_3, advisorPayout); IERC20(mainToken).transfer(_advisorAddress_4, advisorPayout);
                IERC20(mainToken).transfer(_advisorAddress_5, advisorPayout);
            }
            if (marketingPayout > 1 && penalty > 0){
                IERC20(mainToken).transfer(_marketingAddress, marketingPayout);
            }
            //burn(msg.sender, burnAmount);
            bigPayoutPool.add(bpdPoolAmount);
            
            return payOutAmount;
    }

    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) {
            stakeholders.push(_stakeholder); 
            totalStakers = totalStakers.add(1);
        }
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            totalStakers = totalStakers.sub(1);
        } 
    }
}