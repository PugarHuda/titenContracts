// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/PredictionMarket.sol";
import "../src/core/MarketTypes.sol";

contract MockIDRX {
    string public constant name = "Mock IDRX";
    string public constant symbol = "IDRX";
    uint8 public constant decimals = 2;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "insufficient");
        require(allowance[from][msg.sender] >= amount, "not approved");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract PredictionMarketTest is Test {
    PredictionMarket market;
    MockIDRX idrx;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);

    uint256 constant FIXED_STAKE = 1000;

    function setUp() public {
        // 🔥 LOCAL TEST — NO FORK
        idrx = new MockIDRX();
        market = new PredictionMarket(address(idrx), FIXED_STAKE);

        // Mint IDRX
        idrx.mint(alice, 10_000);
        idrx.mint(bob, 10_000);

        // Approve
        vm.prank(alice);
        idrx.approve(address(market), type(uint256).max);

        vm.prank(bob);
        idrx.approve(address(market), type(uint256).max);

        // Control time
        vm.warp(1000);
    }

    function testStakeYes() public {
        market.createMarket("ETH above $4k?", 1 days);

        vm.prank(alice);
        market.stake(0, Side.YES);

        (, , uint256 yesPool, , , ) = market.markets(0);
        assertEq(yesPool, FIXED_STAKE);
    }

    function testStakeNo() public {
        market.createMarket("ETH above $4k?", 1 days);

        vm.prank(bob);
        market.stake(0, Side.NO);

        (, , , uint256 noPool, , ) = market.markets(0);
        assertEq(noPool, FIXED_STAKE);
    }

    function testResolveAndClaim() public {
        market.createMarket("ETH above $4k?", 1 days);

        vm.prank(alice);
        market.stake(0, Side.YES);

        vm.prank(bob);
        market.stake(0, Side.NO);

        uint256 before = idrx.balanceOf(alice);

        market.resolve(0, Side.YES);

        vm.prank(alice);
        market.claim(0);

        uint256 afterBal = idrx.balanceOf(alice);
        assertTrue(afterBal > before);
    }

    function testCannotStakeAfterEnd() public {
        market.createMarket("Short", 1);

        vm.warp(2000);

        vm.prank(alice);
        vm.expectRevert();
        market.stake(0, Side.YES);
    }

    function testCannotClaimIfNotResolved() public {
        market.createMarket("ETH above $4k?", 1 days);

        vm.prank(alice);
        market.stake(0, Side.YES);

        vm.prank(alice);
        vm.expectRevert();
        market.claim(0);
    }
}
