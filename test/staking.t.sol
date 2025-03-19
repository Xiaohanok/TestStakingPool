// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StakingPool.sol";
import "../src/KKToken.sol";

contract StakingTest is Test {
    Staking staking;
    address user1 = address(0x123);
    address user2 = address(0x456);

    function setUp() public {

        // 部署 Staking 合约
        staking = new Staking();


        vm.deal(user1, 10 ether);
        vm.deal(user2, 100 ether);
    }
    function testStakeETH() public {
        vm.startPrank(user1);
        staking.stake{value: 1 ether}();
        vm.stopPrank();

        assertEq(staking.balanceOf(user1), 1 ether, "Stake balance mismatch");
        assertEq(staking.totalSupply(), 1 ether, "Total supply mismatch");
    }

    function testUnstakeETH() public {
        vm.startPrank(user1);
        staking.stake{value: 2 ether}();
        staking.unstake(1 ether);
        vm.stopPrank();

        assertEq(staking.balanceOf(user1), 1 ether, "Unstake balance mismatch");
        assertEq(staking.totalSupply(), 1 ether, "Total supply mismatch");
    }

    function testClaimRewards() public {
        vm.startPrank(user1);
        staking.stake{value: 5 ether}();
        vm.roll(block.number + 10); // 模拟10个区块
        vm.stopPrank();
        vm.prank(user2);
        staking.stake{value: 5 ether}();
        vm.roll(block.number + 10); // 模拟10个区块
        vm.prank(user2);
        staking.stake{value: 10 ether}();
        vm.roll(block.number + 10); // 模拟10个区块
        vm.prank(user2);
        staking.claim();

        KKToken token = KKToken(staking.Token());
       

        uint256 reward = token.balanceOf(user2);
        assertEq(reward, 125000000000000000000, "Claimed reward should be greater than zero");
    }

    function testEarnedCalculation() public {
        vm.startPrank(user1);
        staking.stake{value: 1 ether}();
        vm.roll(block.number + 5); // 模拟5个区块
        uint256 expectedReward = staking.earned(user1);
        vm.stopPrank();

        assertGt(expectedReward, 0, "Earned reward should be greater than zero");
    }

    receive() external payable {}
}