// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./FIRE.sol";
import "./interfaces/IFIRE.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";

contract Swap is AccessControl, FIRE {
    using SafeMath for uint256;
    
    bytes32 public constant ABET_SWAP_ROLE = keccak256("ABET_SWAP_ROLE");
    bytes32 public constant BECN_SWAP_ROLE = keccak256("BECN_SWAP_ROLE");
    bytes32 public constant XAP_SWAP_ROLE = keccak256("XAP_SWAP_ROLE");
    
    
    function grantAbetSwapRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant swap role.");
        grantRole(ABET_SWAP_ROLE, account);
    }
    
    function grantBecnSwapRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant swap role.");
        grantRole(BECN_SWAP_ROLE, account);
    }
    
    function grantXAPSwapRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin can only grant swap role.");
        grantRole(BECN_SWAP_ROLE, account);
    }
    
    
    // ------------------------------------------------------------------------
    //                              Send Functions
    // ------------------------------------------------------------------------
    function sendAbet(address receiver, uint amount) public {
        require(hasRole(ABET_SWAP_ROLE, msg.sender), "Need to be a swapper");
        address swapAddress = ABET_ADDRS;
        
        _balances[swapAddress] = SafeMath.sub(_balances[swapAddress], amount);
        _balances[receiver] = SafeMath.add(_balances[receiver], amount);
        emit Transfer(swapAddress, receiver, amount);
    }
    
    function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
    {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
  }
    
    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
   {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
     
       return (v, r, s);
   }
}