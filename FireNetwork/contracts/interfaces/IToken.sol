// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IToken {
    function mint(address Mint_To, uint256 amount) external;
    function burn(uint256 _value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function externalStake(uint256 amount, uint256 stakingDays, address staker) external;
    function callIncomeStakerTrigger(address staker, uint256 sessionId, uint256 start, uint256 end, uint256 shares) external;
    function callOutcomeStakerTrigger(address staker, uint256 sessionId, uint256 start, uint256 end, uint256 shares) external;
    
    function callIncomeTokensTrigger(uint256 incomeAmountToken) external;
    function transferYearlyPool(uint256 poolNumber) external returns (uint256);
	function getPoolYearAmounts() external view returns (uint256[5] memory poolAmounts);
	
	function getCurrentClaimedAmount() external view returns (uint256);

    function getTotalSnapshotAmount() external view returns (uint256);

    function getCurrentClaimedAddresses() external view returns (uint256);

    function getTotalSnapshotAddresses() external view returns (uint256);
    
    function callIncomeDailyTokensTrigger(uint256 amount) external;

    function callIncomeWeeklyTokensTrigger(uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
