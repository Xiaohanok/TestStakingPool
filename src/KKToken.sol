// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KKToken is ERC20, Ownable {
    uint256 public lastMintBlock;
    uint256 public constant TOKENS_PER_BLOCK = 10 * 10 ** 18; // 每个区块最多 10 个 Token（假设 18 位小数）

    constructor() ERC20("KK Token", "KK") Ownable(msg.sender) {
        lastMintBlock = block.number;
    }

    // 允许合约所有者铸造新的代币，但每个区块最多铸造 10 个 Token
    function mint() external onlyOwner {
    require(block.number > lastMintBlock, "Only one mint per block is allowed");

    uint256 mintAmount = TOKENS_PER_BLOCK * (block.number - lastMintBlock); // 计算应该铸造的代币数量
    _mint(owner(), mintAmount);

    lastMintBlock = block.number;
    }
}
