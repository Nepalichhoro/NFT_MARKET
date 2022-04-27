const { ethers, upgrades } = require('hardhat');

// done for some reasons
async function main () {
  // const Market = await ethers.getContractFactory("Marketplace");
  // console.log('Deploying Marketplace...');
  // // accepted token erc20 token address, banker's address
  // const market = await Market.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0x62D32213e0fE7da5EAf731253FA7FdfA2F6C77C8');
  // await market.deployed();
  // const marketAddress = market.address;
  // console.log(`Deployed Marketplace to address: ${marketAddress}`);

  const BigNFT = await ethers.getContractFactory("BigNFT");
  console.log('Deploying BigNFT...');
  const bigNFT = await upgrades.deployProxy(BigNFT, ['0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'], { initializer: 'initialize' });
  await bigNFT.deployed();
  const nftContractAddress = bigNFT.address;
  console.log(`Deployed BigNFT to address: ${nftContractAddress}`);
}

main();