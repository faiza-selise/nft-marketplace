const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("Should create and execute market sales", async function () {
    const Market = await ethers.getContractFactory("NFTMarket");
    const market = await Market.deploy();
    await market.deployed();
    const marketAddress = market.address; 
    ethers.logger.info("market address:", marketAddress);
    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(marketAddress);
    await nft.deployed();
    const nftContractAddress = nft.address;
    ethers.logger.info("nft address", nftContractAddress);

    let listingPrice = await market.getListingPrice();
    listing = listingPrice.toString();

    const auctionPrice = ethers.utils.parseUnits('100', 'ether');
    
    await nft.createToken("https://www.myTokenLocation.com");
    await nft.createToken("https://www.myTokenLocation2.com");

    await market.createMarketItem(nftContractAddress.toString('hex'), 1, auctionPrice, {value: listingPrice});
    await market.createMarketItem(nftContractAddress.toString('hex'), 2, auctionPrice, {value: listingPrice});

    const [_, buyerAddress] = await ethers.getSigners();
    ethers.logger.info("buyerAddress", buyerAddress);

    /* execute sale of token to another user */
   const data = await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, { value: auctionPrice });
    ethers.logger.info("data", data);

    let items = await market.fetchMarketItems();
    items = await Promise.all(items.map(async i => {
      const tokenUri = await nft.tokenURI(i.tokenId)
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item
    }))
    console.log('items: ', items)
  })
  });
