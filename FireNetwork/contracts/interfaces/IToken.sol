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
        function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
