// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract CreatorRewardModule is Ownable {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable IDRX;
    uint256 public immutable CREATOR_REWARD;

    // marketId => creator
    mapping(uint256 => address) public marketCreator;

    // marketId => rewarded?
    mapping(uint256 => bool) public rewarded;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CreatorRegistered(uint256 indexed marketId, address indexed creator);
    event CreatorRewarded(uint256 indexed marketId, address indexed creator, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _idrx, uint256 _creatorReward)
        Ownable(msg.sender)
    {
        IDRX = IERC20(_idrx);
        CREATOR_REWARD = _creatorReward;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register creator for a market (called when market is approved)
     */
    function registerCreator(uint256 marketId, address creator)
        external
        onlyOwner
    {
        marketCreator[marketId] = creator;
        emit CreatorRegistered(marketId, creator);
    }

    /**
     * @notice Reward creator after market creation
     */
    function rewardCreator(uint256 marketId)
        external
        onlyOwner
    {
        require(!rewarded[marketId], "Already rewarded");

        address creator = marketCreator[marketId];
        require(creator != address(0), "No creator");

        rewarded[marketId] = true;
        IDRX.transfer(creator, CREATOR_REWARD);

        emit CreatorRewarded(marketId, creator, CREATOR_REWARD);
    }
}
