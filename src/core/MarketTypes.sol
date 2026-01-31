// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum Side {
    NONE,
    YES,
    NO
}

struct Market {
    string question;
    uint256 endTime;
    uint256 yesPool;
    uint256 noPool;
    bool resolved;
    Side winningSide;
}
