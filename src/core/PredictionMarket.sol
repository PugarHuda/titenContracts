// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MarketStorage.sol";
import "./MarketTypes.sol";
import "../libs/MathLib.sol";
import "../errors/Errors.sol";

contract PredictionMarket is MarketStorage, Ownable {
    IERC20 public immutable idrx;
    // ❌ fixedStake DIHAPUS

    event MarketCreated(uint256 indexed id, string question, uint256 endTime);
    // ✅ Event diupdate biar frontend tau berapa yang di-stake
    event Staked(address indexed user, uint256 indexed id, Side side, uint256 amount);
    event MarketResolved(uint256 indexed id, Side result);
    event RewardClaimed(address indexed user, uint256 indexed id, uint256 amount);

    // ✅ Constructor HANYA terima address token
    constructor(address _idrx) Ownable(msg.sender) {
        idrx = IERC20(_idrx);
    }

    /* ========= MARKET CREATION ========= */
    function createMarket(string calldata question, uint256 duration)
        external
        onlyOwner
    {
        markets[marketCount] = Market({
            question: question,
            endTime: block.timestamp + duration,
            yesPool: 0,
            noPool: 0,
            resolved: false,
            winningSide: Side.NONE
        });

        emit MarketCreated(
            marketCount,
            question,
            block.timestamp + duration
        );
        marketCount++;
    }

    /* ========= STAKE (DYNAMIC) ========= */
    // ✅ Tambah parameter 'amount'
    function stake(uint256 id, Side side, uint256 amount) external {
        Market storage m = markets[id];

        if (amount == 0) revert("Amount must be > 0"); // Validasi
        if (block.timestamp >= m.endTime) revert MarketEnded();
        if (m.resolved) revert MarketAlreadyResolved();
        if (side != Side.YES && side != Side.NO) revert InvalidSide();

        // Transfer Dynamic Amount
        idrx.transferFrom(msg.sender, address(this), amount);

        userStakes[msg.sender][id][side] += amount;

        if (side == Side.YES) {
            m.yesPool += amount;
        } else {
            m.noPool += amount;
        }

        // Emit event dengan amount
        emit Staked(msg.sender, id, side, amount);
    }

    /* ========= RESOLVE ========= */
    function resolve(uint256 id, Side result) external onlyOwner {
        Market storage m = markets[id];

        if (m.resolved) revert MarketAlreadyResolved();
        if (result != Side.YES && result != Side.NO) revert InvalidSide();

        m.resolved = true;
        m.winningSide = result;

        emit MarketResolved(id, result);
    }

    /* ========= CLAIM ========= */
    function claim(uint256 id) external {
        Market storage m = markets[id];
        if (!m.resolved) revert NotResolved();

        uint256 userAmount = userStakes[msg.sender][id][m.winningSide];
        if (userAmount == 0) revert NothingToClaim();

        uint256 reward = MathLib.calculateReward(
            userAmount,
            m.winningSide == Side.YES ? m.yesPool : m.noPool,
            m.winningSide == Side.YES ? m.noPool : m.yesPool
        );

        userStakes[msg.sender][id][m.winningSide] = 0;
        idrx.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, id, reward);
    }
}