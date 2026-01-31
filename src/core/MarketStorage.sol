// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MarketTypes.sol";

contract MarketStorage {
    uint256 public marketCount;

    mapping(uint256 => Market) public markets;

    // user => marketId => side => amount
    mapping(address => mapping(uint256 => mapping(Side => uint256)))
        public userStakes;
}
