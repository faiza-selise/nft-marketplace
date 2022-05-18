
const hre = require("hardhat");

async function main() {
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarket");
  const nftMarketplace = await NFTMarketplace.deploy();
  await nftMarketplace.deployed();
  console.log("nftMarketplace deployed to:", nftMarketplace.address);

  const NFT = await hre.ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(nftMarketplace.address);

  await nft.deployed();

  console.log("nft deployed to:", nft.address);

  // const PremiumPack = await hre.ethers.getContractFactory("PremiumPack");
  // const premiumPack = await PremiumPack.deploy("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "0x70997970c51812dc3a010c7d01b50e0d17dc79c8");

  // await premiumPack.deployed();

  // console.log("premiumPack deployed to:", premiumPack.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
