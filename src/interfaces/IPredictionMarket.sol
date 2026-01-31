// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketTypes.sol";

interface IPredictionMarket {
    function stake(uint256 marketId, Side side) external;
    function claim(uint256 marketId) external;
}
