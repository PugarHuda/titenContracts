// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/modules/CreatorRewardModule.sol";

/*//////////////////////////////////////////////////////////////
                        MOCK ERC20 (LOCAL)
//////////////////////////////////////////////////////////////*/
contract MockIDRX {
    string public constant name = "Mock IDRX";
    string public constant symbol = "IDRX";
    uint8 public constant decimals = 2;

    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/*//////////////////////////////////////////////////////////////
                        TEST CONTRACT
//////////////////////////////////////////////////////////////*/
contract CreatorRewardModuleTest is Test {
    CreatorRewardModule module;
    MockIDRX idrx;

    address owner = address(this);
    address creator = address(0xCAFE);
    address attacker = address(0xBAD);

    uint256 constant CREATOR_REWARD = 500; // 5 IDRX (2 decimals)

    function setUp() public {
        // Deploy mock token
        idrx = new MockIDRX();

        // Deploy module
        module = new CreatorRewardModule(address(idrx), CREATOR_REWARD);

        // Fund module with IDRX
        idrx.mint(address(module), 10_000);
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTER CREATOR
    //////////////////////////////////////////////////////////////*/

    function testRegisterCreator() public {
        module.registerCreator(0, creator);

        assertEq(module.marketCreator(0), creator);
    }

    function testOnlyOwnerCanRegister() public {
        vm.prank(attacker);
        vm.expectRevert();
        module.registerCreator(0, creator);
    }

    /*//////////////////////////////////////////////////////////////
                        REWARD CREATOR
    //////////////////////////////////////////////////////////////*/

    function testRewardCreator() public {
        module.registerCreator(1, creator);

        uint256 before = idrx.balanceOf(creator);

        module.rewardCreator(1);

        uint256 afterBal = idrx.balanceOf(creator);

        assertEq(afterBal - before, CREATOR_REWARD);
        assertTrue(module.rewarded(1));
    }

    function testCannotRewardTwice() public {
        module.registerCreator(2, creator);
        module.rewardCreator(2);

        vm.expectRevert("Already rewarded");
        module.rewardCreator(2);
    }

    function testCannotRewardIfNoCreator() public {
        vm.expectRevert("No creator");
        module.rewardCreator(99);
    }

    function testOnlyOwnerCanReward() public {
        module.registerCreator(3, creator);

        vm.prank(attacker);
        vm.expectRevert();
        module.rewardCreator(3);
    }
}
