// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KKToken.sol";

/**
 * @title Staking 合约
 * @dev 允许用户质押 ETH 来获取 KK Token 奖励
 */
contract Staking {
    KKToken public Token;
    uint256 public globalR;
    uint256 public lastUpdateBlock;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userR;
    uint256 public totalSupply;
    uint256 public constant REWARD_PER_BLOCK = 10e18;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    modifier updateGlobalR() {
        if (block.number > lastUpdateBlock && totalSupply > 0) {
            uint256 blockDelta = block.number - lastUpdateBlock;
            uint256 deltaR = (REWARD_PER_BLOCK * blockDelta) / totalSupply;
            globalR += deltaR;
        }
        lastUpdateBlock = block.number;
        _;
    }

    modifier updateUserReward(address account) {
        if (account != address(0)) {
            uint256 rDelta = globalR - userR[account];
            if (rDelta > 0) {
                uint256 pending = (balances[account] * rDelta);
                if (pending > 0) {
                    rewards[account] += pending;
                }
                userR[account] = globalR;
            }
        }
        _;
    }

    constructor() {
        Token = new KKToken();
        lastUpdateBlock = block.number;
    }

    receive() external payable {
        stake();
    }

    function stake()
        public
        payable
        updateGlobalR
        updateUserReward(msg.sender)
    {
        require(msg.value > 0, "Cannot stake 0 ETH");
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount)
        external
        updateGlobalR
        updateUserReward(msg.sender)
    {
        require(balances[msg.sender] >= amount, "Not enough staked");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claim()
        external
        updateGlobalR
        updateUserReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        Token.mint();
        require(Token.transfer(msg.sender, reward), "Token transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    function earned(address account) external view returns (uint256) {
        uint256 tempGlobalR = globalR;
        if (block.number > lastUpdateBlock && totalSupply > 0) {
            uint256 blockDelta = block.number - lastUpdateBlock;
            uint256 deltaR = (REWARD_PER_BLOCK * blockDelta) / totalSupply;
            tempGlobalR += deltaR;
        }
        uint256 rDelta = tempGlobalR - userR[account];
        uint256 pending = (balances[account] * rDelta);
        return rewards[account] + pending;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }
}