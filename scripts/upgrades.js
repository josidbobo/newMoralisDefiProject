require('@openzeppelin/hardhat-upgrades');

// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BlockV2 = await ethers.getContractFactory("BlockV2");
  const blockV2 = await upgrades.upgradeProxy(BOX_ADDRESS, BlockV2); // Old address : New address
  console.log("Box upgraded");
}

main();